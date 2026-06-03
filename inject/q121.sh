#!/usr/bin/env bash
set -euo pipefail
ip link delete bondlfcs5 >/dev/null 2>&1 || true
ip link delete bnd5a >/dev/null 2>&1 || true
ip link delete bnd5b >/dev/null 2>&1 || true
