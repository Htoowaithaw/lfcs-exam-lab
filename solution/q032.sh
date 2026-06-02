#!/usr/bin/env bash
set -euo pipefail
grep -vE '^[[:space:]]*(#|$)' /var/tmp/ec-q032/sshd.conf > /root/q032-active.conf
