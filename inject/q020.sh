#!/usr/bin/env bash
set -euo pipefail
rm -rf /var/tmp/ec-q020 /srv/ec-q020
mkdir -p /var/tmp/ec-q020/source/sub /srv/ec-q020/mirror
printf 'main\n' > /var/tmp/ec-q020/source/app.conf
printf 'sub\n' > /var/tmp/ec-q020/source/sub/db.conf
printf 'temp\n' > /var/tmp/ec-q020/source/cache.tmp
printf 'stale\n' > /srv/ec-q020/mirror/stale.txt
