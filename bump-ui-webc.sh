#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <version>" >&2
  echo "Example: $0 4.3.5" >&2
  exit 1
fi

VERSION="$1"

if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Error: version must be in X.Y.Z form (got: $VERSION)" >&2
  exit 1
fi

cd "$(dirname "$0")"

sed -i.bak -E "s|@scouterna/ui-webc@[0-9]+\.[0-9]+\.[0-9]+|@scouterna/ui-webc@${VERSION}|g" \
  client/gleam.toml
rm client/gleam.toml.bak

sed -i.bak -E "s|const scouterna_ui_webc_version = \"[0-9]+\.[0-9]+\.[0-9]+\"|pub const ui_webc_version = \"${VERSION}\"|" \
  server/src/server/web.gleam
rm server/src/server/web.gleam.bak

echo "Bumped @scouterna/ui-webc to ${VERSION}"
