#!/usr/bin/env bash
set -euo pipefail
userdel -r remoteuser5 >/dev/null 2>&1 || true
rm -f /vagrant/.tmp-q229.pub
