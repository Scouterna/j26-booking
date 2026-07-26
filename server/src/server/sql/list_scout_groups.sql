-- Every registered kår, for the book-for-other kår picker
-- (`/api/scout-groups`). The client sorts and filters the list itself, but
-- return a stable name order so the payload (and its ETag) is deterministic.
SELECT id,
    name
FROM scout_group
ORDER BY name ASC,
    id ASC;
