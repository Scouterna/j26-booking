--- migration:up
-- Authorization now comes from the JWT (resource_access.j26-booking.roles);
-- the role column was never read by any query.
ALTER TABLE "user" DROP COLUMN role;
DROP TYPE user_role;

--- migration:down
CREATE TYPE user_role AS ENUM ('organizer', 'booker', 'admin');
ALTER TABLE "user" ADD COLUMN role user_role NOT NULL DEFAULT 'booker';
ALTER TABLE "user" ALTER COLUMN role DROP DEFAULT;

--- migration:end
