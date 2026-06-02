#!/usr/bin/env bash
set -euo pipefail
rsync -a --delete --delete-excluded --include='*/' --include='*.conf' --exclude='*' /var/tmp/ec-q020/source/ /srv/ec-q020/mirror/
