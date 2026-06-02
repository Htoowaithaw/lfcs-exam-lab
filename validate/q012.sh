#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }

base=/opt/ec-q012
[ -d "$base/releases/2026.06" ] || fail "release directory missing"
[ -d "$base/shared/cache" ] || fail "shared cache missing"
[ -d "$base/shared/tmp" ] || fail "shared tmp missing"
[ "$(stat -c %a "$base/shared/tmp")" = "1777" ] || fail "shared tmp mode is not 1777"
[ -f "$base/releases/2026.06/VERSION" ] || fail "VERSION file missing"
grep -qx '2026.06' "$base/releases/2026.06/VERSION" || fail "VERSION content incorrect"
[ -L "$base/current" ] || fail "current symlink missing"
[ "$(readlink "$base/current")" = "releases/2026.06" ] || fail "current symlink target incorrect"
echo "RESULT: PASS"
