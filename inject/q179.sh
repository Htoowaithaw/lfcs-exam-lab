#!/usr/bin/env bash
set -euo pipefail
userdel -r grpuser1 >/dev/null 2>&1 || true
groupdel lfcsteam1 >/dev/null 2>&1 || true
