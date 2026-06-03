#!/usr/bin/env bash
set -euo pipefail
ip link delete brlfcs1 >/dev/null 2>&1 || true
ip link delete brd1a >/dev/null 2>&1 || true
ip link delete brd1b >/dev/null 2>&1 || true
