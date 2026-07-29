--- migration:up
-- Badbuss departure check-offs: the two boarding stages the beach-bus staff
-- tick off per booking (per kår) on a slot — left the campsite, then left the
-- beach. Only meaningful for bookings on a slot whose
-- activity.recurring_activity_kind = 'beach-bus'; the columns exist on every
-- booking because they hang off the booking, and the API refuses to set them
-- for any other kind of activity.
--
-- Deliberately additive and non-destructive: both columns are new, NOT NULL
-- with a constant FALSE default, so PostgreSQL fills them in from the catalog
-- without rewriting the table and every existing booking keeps all of its
-- current values (nothing is read, moved, or re-typed).
ALTER TABLE booking ADD COLUMN left_campsite BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE booking ADD COLUMN left_beach BOOLEAN NOT NULL DEFAULT FALSE;
--- migration:down
ALTER TABLE booking DROP COLUMN left_campsite;
ALTER TABLE booking DROP COLUMN left_beach;
--- migration:end
