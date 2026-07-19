# Plans & handoffs

This folder holds implementation plans and handoff docs — one Markdown file per
piece of work, written before (or during) implementation so another agent or
developer can pick it up.

## Rules for agents

When you create, finish, or touch a plan here, keep the folder consistent:

1. **Serial prefix.** Every file is named `NN-kebab-title.md` and its H1 is
   `# NN. Title`, where `NN` is a zero-padded serial. Order is by **completion
   date** (done date) first, falling back to **creation date** for plans that
   are not done yet. New plans get the next unused serial.
2. **Status header.** Immediately under the H1, every file carries a status
   blockquote:
   - `> **Status: 🔲 Not started** (as of YYYY-MM-DD)`
   - `> **Status: 🚧 In progress** (as of YYYY-MM-DD)`
   - `> **Status: ✅ Done YYYY-MM-DD** (commit \`<sha>\`; notes)`
   When a plan ships, flip it to ✅ with the real done date and commit, and add
   a short note if the implementation diverged from the plan.
3. **Keep the index below current.** Add a row for each new plan; update the
   status column when it changes.

## Index

| # | Plan | Status |
| - | ---- | ------ |
| 01 | [Emit j26:navigate on every route change](01-solve-this-todo-witty-barto.md) | ✅ Done 2026-07-02 |
| 02 | [Normalized activity store + favourites endpoint](02-normalized-activity-store-and-favourites-endpoint.md) | ✅ Done 2026-07-02 |
| 03 | [Model badbuss & klättervägg as activity categories](03-model-special-activity-categories.md) | ✅ Done 2026-07-02 (different design) |
| 04 | [Real "spots remaining" via activity-spots API](04-activity-spots-remaining-calculation.md) | ✅ Done 2026-07-03 |
| 05 | [Bilingual title & description for activities](05-bilingual-activity-title-description.md) | ✅ Done 2026-07-08 |
| 06 | [Optional booker group + store booker_name from JWT](06-booking-optional-group-and-booker-name-handoff.md) | ✅ Done 2026-07-08 |
| 07 | [Client-side shell→iframe navigation (no reload on back)](07-shell-iframe-clientside-navigation.md) | ✅ Done 2026-07-14 (j26-app `fa57af0`, different design) |
| 08 | [Activity tags & målgrupp (real, not mocked)](08-activity-tags-and-malgrupp.md) | ✅ Done 2026-07-10 |
| 09 | [ETag revalidation for per-day activity lists](09-etag-revalidation-per-day-activity-lists.md) | ✅ Done 2026-07-16 |
| 10 | [Activity add/edit form in a drawer (consistent with booking)](10-activity-form-drawer.md) | ✅ Done 2026-07-17 |
| 11 | [Day-windowed activity lists](11-day-windowed-activity-lists.md) | ✅ Done 2026-07-17 |
| 12 | [Persist the day filter across navigation (issue #40)](12-day-filter-persistence.md) | ✅ Done 2026-07-17 |
| 13 | [Persist the activity cache across app switches (instant reopen)](13-persist-activity-cache-across-app-switches.md) | 🔲 Not started |
| 14 | [Show group free-text on recurring-booking slot cards](14-recurring-slot-card-group-free-text.md) | 🔲 Not started |
| 15 | [Create a booking for someone else (issue #27)](15-book-for-someone-else.md) | ✅ Done 2026-07-19 |
| 16 | [Multiple bookings per person + manage-bookings interface](16-multiple-bookings-and-manage-bookings-page.md) | ✅ Done 2026-07-19 |
| 17 | [`bookings:others:create` manages every booking](17-others-create-manages-all-bookings.md) | 🔲 Not started |
