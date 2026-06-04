#!/usr/bin/env bash
set -euo pipefail
chown root:adm /srv/lfcs/q002/secret.txt
chmod 0640 /srv/lfcs/q002/secret.txt
ln -sfn /srv/lfcs/q002/secret.txt /opt/q002-secret
