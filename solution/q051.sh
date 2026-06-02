#!/usr/bin/env bash
set -euo pipefail
chgrp -R adm /srv/ec-q051/project
find /srv/ec-q051/project -type d -exec chmod 2770 {} +
find /srv/ec-q051/project -type f -exec chmod 0660 {} +
