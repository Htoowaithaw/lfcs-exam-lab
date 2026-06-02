#!/usr/bin/env bash
set -euo pipefail
openssl req -x509 -nodes -newkey rsa:2048 -days 31 -keyout /etc/ssl/private/lfcs-op-tls1.key -out /etc/ssl/certs/lfcs-op-tls1.crt -subj '/CN=lfcs-op-tls1.lfcs.local'
chmod 0600 /etc/ssl/private/lfcs-op-tls1.key
