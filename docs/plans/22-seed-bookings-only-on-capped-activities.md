# 22. Seed bookings only on capped activities

> **Status: 🔲 Not started** (as of 2026-07-20)

## Context

The seed expansion (`2fd6eda`, **unpushed, local main only**) generated ~765
bookings in `server/priv/seeding/bookings.sql`, but 624 of them target
activities with `max_attendees IS NULL`. That violates the product rule
(client-enforced since plan 16 / `13834ee`): **uncapped activities are not
booked** — no Boka button, no "Behöver bokas" chip, no "Visa bokningar".
The fake rows made role holders' UIs look broken (self-"booked" activities
without a Visa bokningar button) and misrepresent real-world data.

Bookings on uncapped activities also can't be flagged bad by the server —
`web.exceeds_capacity(None, ..)` is always `False` and `create` has no other
cap guard — so nothing catches them at seed time. (Server-side enforcement is
deliberately out of scope here; if wanted, it belongs with plan 21's handler
work or its own issue.)

## Changes

1. **Filter `server/priv/seeding/bookings.sql`** (on local main, where
   `2fd6eda` lives — this worktree's base predates it): drop every generated
   booking tuple whose `activity_id` is uncapped. The caps live in the same
   commit's `server/priv/seeding/activities.sql`; a small throwaway script
   (scratchpad, not committed) can parse the activity ids with non-null
   `max_attendees` and rewrite `bookings.sql` keeping only matching tuples.
   - Keep the 7 hand-written `dd000001`–`dd000007` fixtures (all on capped
     activities) untouched — plans 16/17 reference them by id.
   - The favourites seed (`INSERT INTO favourite … SELECT FROM booking`)
     self-adjusts, but hearted-only favourites on uncapped activities are
     fine and should stay.
   - Check the 8 call-offs still reference activities that kept bookings
     ("call-offs on booked activities" was part of the commit's intent);
     re-point any that no longer do.
2. **Re-verify capacity-awareness**: after filtering, assert no activity's
   summed `participant_count` exceeds its `max_attendees` (one SQL query on a
   freshly seeded DB).
3. **Clean the live dev DB** (destructive — needs explicit go-ahead):
   `DELETE FROM booking b USING activity a WHERE a.id = b.activity_id AND
   a.max_attendees IS NULL;` (~624 rows). Favourites stay (a heart on an
   uncapped activity is legitimate).
4. **Commit** on main as `fix(db): seed bookings only on capped activities`
   (or amend `2fd6eda` if it is still unpushed when the fix lands).

## Verification

- Fresh DB → `gleam run -m cigogne all` → `./seed.sh` → the query in (2)
  returns no rows, and `SELECT count(*) FROM booking b JOIN activity a ON
  a.id = b.activity_id WHERE a.max_attendees IS NULL` = 0.
- `./seed.sh` twice in a row still succeeds (idempotence, ON CONFLICT).
- UI as `DEV_AUTH_ROLES=bookings:others:create`: no uncapped activity shows
  a booked state; capped booked activities show "Visa bokningar" as before.

## Handoff notes

- The bad rows were how the "missing Visa bokningar" report arose — the
  button gate (`client.gleam` detail view, `option.is_some(max_attendees)`)
  is *correct* and must not be "fixed".
- The dead instant-book-uncapped path in `UserClickedBook` (+ its two tests)
  is a separate confusion left from plan 15; removing it is optional and not
  part of this plan.
