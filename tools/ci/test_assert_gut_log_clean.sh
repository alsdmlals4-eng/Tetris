#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
checker="$script_dir/assert_gut_log_clean.sh"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

printf '%s\n' 'Tests 45' 'Passing Tests 45' > "$tmp_dir/clean.log"
bash "$checker" "$tmp_dir/clean.log"

assert_rejected() {
  local name="$1"
  local line="$2"
  printf '%s\n' "$line" > "$tmp_dir/$name.log"
  if bash "$checker" "$tmp_dir/$name.log" >/dev/null 2>&1; then
    echo "expected strict checker to reject $name" >&2
    exit 1
  fi
}

assert_rejected parse 'SCRIPT ERROR: Parse Error: Cannot infer the type of variable'
assert_rejected load 'ERROR: Failed to load script "res://tests/unit/test_bad.gd" with error "Parse error".'
assert_rejected ignored '[GUT WARNING]:  Ignoring script res://tests/unit/test_bad.gd because it does not extend GutTest'

echo '[STRICT_GUT_TEST] PASS'
