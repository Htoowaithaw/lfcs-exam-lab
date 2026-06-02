#!/usr/bin/env bash
set -euo pipefail
setfacl -m u:nobody:r-- /srv/ec-q055/secret.txt
chmod 0640 /srv/ec-q055/secret.txt
