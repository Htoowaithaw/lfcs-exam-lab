#!/usr/bin/env bash
set -euo pipefail
mkdir -p /srv/lfcs/ec-layout/{bin,conf,logs/archive}
mv /var/tmp/ec-q011/app.conf /srv/lfcs/ec-layout/conf/config.ini
: > /srv/lfcs/ec-layout/bin/run-check
chmod 0755 /srv/lfcs/ec-layout/bin/run-check
ln -s logs/current.log /srv/lfcs/ec-layout/latest-log
