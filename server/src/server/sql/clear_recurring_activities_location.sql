-- Remove the location from every slot of a recurring activity kind. The
-- kind-wide counterpart of clear_activity_location.
UPDATE activity
SET location_id = NULL
WHERE recurring_activity_kind = $1;
