#!/usr/bin/env bash
set -euo pipefail
userdel -r grpuser2 >/dev/null 2>&1 || true
groupdel lfcsteam2 >/dev/null 2>&1 || true
