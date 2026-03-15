#!/bin/bash
input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

[[ "$file_path" == *.gleam ]] || exit 0

dir=$(dirname "$file_path")
while [[ "$dir" != "/" ]]; do
  if [[ -f "$dir/gleam.toml" ]]; then
    gleam format "$file_path" --check > /dev/null 2>&1 || gleam format "$file_path" > /dev/null 2>&1
    exit 0
  fi
  dir=$(dirname "$dir")
done
