#!/usr/bin/env bash
set -euo pipefail
rm -rf /srv/lfcs/q002 /opt/q002-secret
mkdir -p /srv/lfcs/q002
printf 'classified\n' > /srv/lfcs/q002/secret.txt
chown root:root /srv/lfcs/q002/secret.txt
chmod 0600 /srv/lfcs/q002/secret.txt
