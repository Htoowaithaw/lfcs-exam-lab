#!/usr/bin/env bash
set -euo pipefail
userdel -r remoteuser4 >/dev/null 2>&1 || true
rm -f /vagrant/.tmp-q228.pub
