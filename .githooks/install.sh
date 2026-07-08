#!/usr/bin/env bash
#
# Enable the repo's tracked git hooks. Run once after cloning:
#
#     ./.githooks/install.sh
#
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
git -C "$repo_root" config core.hooksPath .githooks
echo "Git hooks enabled (core.hooksPath = .githooks)."
