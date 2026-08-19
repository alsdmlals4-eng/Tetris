#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <gut-log>" >&2
  exit 2
fi

log_path="$1"

if [[ ! -f "$log_path" ]]; then
  echo "[STRICT_GUT] log not found: $log_path" >&2
  exit 2
fi

if grep -Eq 'SCRIPT ERROR: Parse Error:|ERROR: Failed to load script|\[GUT WARNING\]:[[:space:]]+Ignoring script .* because it does not extend GutTest' "$log_path"; then
  echo "[STRICT_GUT] test collection/parse failure detected" >&2
  grep -En 'SCRIPT ERROR: Parse Error:|ERROR: Failed to load script|\[GUT WARNING\]:[[:space:]]+Ignoring script .* because it does not extend GutTest' "$log_path" >&2 || true
  exit 1
fi
