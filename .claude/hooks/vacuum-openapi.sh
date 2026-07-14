#!/bin/bash
#
# PostToolUse hook: lint the OpenAPI spec with vacuum after Claude edits it.
# Fires on Edit|Write; only acts on files named openapi.yaml. Runs from the
# project root so vacuum.conf.yaml (which points at vacuum-ruleset.yaml) is
# picked up. On any warning/error, the report is written to stderr and the hook
# exits 2, feeding the findings back to Claude; a clean spec exits 0 silently.
input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

[[ "$file_path" == *openapi.yaml ]] || exit 0
[[ -f "$file_path" ]] || exit 0
command -v vacuum >/dev/null 2>&1 || exit 0

root="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$file_path")" && git rev-parse --show-toplevel 2>/dev/null)}"
[[ -n "$root" ]] || root="."

report=$(cd "$root" && vacuum lint -q -b -d --no-clip -n warn "$file_path" 2>&1)
if [[ $? -ne 0 ]]; then
  echo "vacuum found issues in $file_path:" >&2
  echo "$report" >&2
  exit 2
fi
exit 0
