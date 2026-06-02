#!/usr/bin/env bash
set -euo pipefail
mkdir -p /opt/ec-q012/releases/2026.06 /opt/ec-q012/shared/tmp /opt/ec-q012/shared/cache
cp /var/tmp/ec-q012/VERSION /opt/ec-q012/releases/2026.06/VERSION
chmod 1777 /opt/ec-q012/shared/tmp
ln -s releases/2026.06 /opt/ec-q012/current
