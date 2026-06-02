#!/usr/bin/env bash
set -euo pipefail
openssl req -x509 -nodes -newkey rsa:2048 -days 32 -keyout /etc/ssl/private/lfcs-op-tls2.key -out /etc/ssl/certs/lfcs-op-tls2.crt -subj '/CN=lfcs-op-tls2.lfcs.local'
chmod 0600 /etc/ssl/private/lfcs-op-tls2.key
