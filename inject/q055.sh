#!/usr/bin/env bash
set -euo pipefail
rm -rf /srv/ec-q055
mkdir -p /srv/ec-q055
printf 'secret\n' > /srv/ec-q055/secret.txt
chmod 0600 /srv/ec-q055/secret.txt
