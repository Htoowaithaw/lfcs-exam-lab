#!/usr/bin/env bash
set -euo pipefail
rm -rf /srv/ec-q051
mkdir -p /srv/ec-q051/project/sub
printf x > /srv/ec-q051/project/a.txt
printf y > /srv/ec-q051/project/sub/b.txt
chmod -R 0755 /srv/ec-q051/project
