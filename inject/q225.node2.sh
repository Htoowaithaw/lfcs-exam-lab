#!/usr/bin/env bash
set -euo pipefail
userdel -r remoteuser1 >/dev/null 2>&1 || true
rm -f /vagrant/.tmp-q225.pub
