#!/usr/bin/env bash
set -euo pipefail
userdel -r grpuser3 >/dev/null 2>&1 || true
groupdel lfcsteam3 >/dev/null 2>&1 || true
