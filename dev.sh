#!/bin/sh
set -e

export BASE_PATH="/_services/booking"

cd client && gleam run -m lustre/dev build --minify --outdir=../server/priv/static
cd ../server && gleam run
