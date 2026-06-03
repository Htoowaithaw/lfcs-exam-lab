#!/usr/bin/env bash
set -euo pipefail
userdel -r remoteuser2 >/dev/null 2>&1 || true
rm -f /vagrant/.tmp-q226.pub
