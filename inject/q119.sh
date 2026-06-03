#!/usr/bin/env bash
set -euo pipefail
ip link delete brlfcs3 >/dev/null 2>&1 || true
ip link delete brd3a >/dev/null 2>&1 || true
ip link delete brd3b >/dev/null 2>&1 || true
