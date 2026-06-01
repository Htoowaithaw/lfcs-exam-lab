#!/usr/bin/env bash
set -euo pipefail
userdel -r alice >/dev/null 2>&1 || true
userdel -r bob >/dev/null 2>&1 || true
groupdel webops >/dev/null 2>&1 || true
rm -rf /srv/web
