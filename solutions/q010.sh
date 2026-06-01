#!/usr/bin/env bash
set -euo pipefail
groupadd webops
useradd -m -G webops alice
useradd -m -G webops bob
mkdir -p /srv/web
chown root:webops /srv/web
chmod 2775 /srv/web
