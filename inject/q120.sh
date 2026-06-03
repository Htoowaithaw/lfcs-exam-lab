#!/usr/bin/env bash
set -euo pipefail
ip link delete bondlfcs4 >/dev/null 2>&1 || true
ip link delete bnd4a >/dev/null 2>&1 || true
ip link delete bnd4b >/dev/null 2>&1 || true
