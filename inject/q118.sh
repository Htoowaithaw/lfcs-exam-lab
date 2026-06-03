#!/usr/bin/env bash
set -euo pipefail
ip link delete brlfcs2 >/dev/null 2>&1 || true
ip link delete brd2a >/dev/null 2>&1 || true
ip link delete brd2b >/dev/null 2>&1 || true
