#!/bin/sh
set -e

# Source local environment variables if available
if [ -f .env.sh ]; then
  . ./.env.sh
fi

(cd client && gleam run -m lustre/dev build --minify --outdir=../server/priv/static)
(cd server && gleam run)