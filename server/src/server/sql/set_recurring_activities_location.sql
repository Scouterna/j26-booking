-- Point every slot of a recurring activity kind at the same location. The
-- kind-wide counterpart of set_activity_location (a separate query from the
-- bulk text update because squirrel parameters cannot be optional).
UPDATE activity
SET location_id = $2
WHERE recurring_activity_kind = $1;
