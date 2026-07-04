#!/bin/sh
set -e

# Source local environment variables if available
if [ -f .env.sh ]; then
  . ./.env.sh
fi

# Locations must be seeded before activities, which reference them via
# location_id; bookings reference activities, so they come last.
psql "$DATABASE_URL" -f server/priv/seeding/locations.sql
psql "$DATABASE_URL" -f server/priv/seeding/activities.sql
psql "$DATABASE_URL" -f server/priv/seeding/bookings.sql
