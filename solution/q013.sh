#!/usr/bin/env bash
set -euo pipefail
mkdir -p /srv/ec-q013/{docs,bin,data}
mv /var/tmp/ec-q013/incoming/*.md /srv/ec-q013/docs/
mv /var/tmp/ec-q013/incoming/*.sh /srv/ec-q013/bin/
mv /var/tmp/ec-q013/incoming/*.csv /srv/ec-q013/data/
chmod 0755 /srv/ec-q013/bin/*.sh
