-- Bulk-apply the shared text fields of a recurring activity kind (badbuss /
-- klättervägg) to every slot of that kind. The slots duplicate these fields,
-- so they are always written together; per-slot fields (times, capacity) are
-- untouched. Returns the updated ids so the handler can report the count.
UPDATE activity
SET title = $2,
    title_en = $3,
    description = $4,
    description_en = $5
WHERE recurring_activity_kind = $1
RETURNING id;
