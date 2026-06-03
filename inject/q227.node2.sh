#!/usr/bin/env bash
set -euo pipefail
userdel -r remoteuser3 >/dev/null 2>&1 || true
rm -f /vagrant/.tmp-q227.pub
