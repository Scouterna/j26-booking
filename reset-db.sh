#!/bin/sh
set -e

# Source local environment variables if available
if [ -f .env.sh ]; then
  . ./.env.sh
fi

echo "This will DELETE ALL DATA from the database: $DATABASE_URL"
printf "Type 'yes' to confirm: "
read confirmation

if [ "$confirmation" != "yes" ]; then
  echo "Aborted."
  exit 1
fi

psql "$DATABASE_URL" -c "DELETE FROM activity_user; DELETE FROM booking; DELETE FROM \"user\"; DELETE FROM activity;"
echo "All tables cleared."
