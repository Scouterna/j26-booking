#!/bin/sh
set -e

# Source local environment variables if available
if [ -f .env.sh ]; then
  . ./.env.sh
fi

psql "$DATABASE_URL" -f server/priv/seeding/activities.sql
