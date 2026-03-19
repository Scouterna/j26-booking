#!/bin/sh
set -e

# Source local environment variables if available
if [ -f .env.sh ]; then
  . ./.env.sh
fi

# cd client && gleam run -m lustre/dev build --minify --outdir=../server/priv/static

# Start both processes in parallel so they can run together.
(cd client && gleam run -m lustre/dev start) &
client_pid=$!

(cd server && gleam run) &
server_pid=$!

cleanup() {
  trap - INT TERM EXIT
  kill "$client_pid" "$server_pid" 2>/dev/null || true
  wait "$client_pid" "$server_pid" 2>/dev/null || true
}

# Ensure Ctrl+C (INT) and termination signals stop both processes.
trap cleanup INT TERM EXIT

wait "$client_pid" "$server_pid"
