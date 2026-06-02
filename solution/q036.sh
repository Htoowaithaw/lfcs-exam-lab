#!/usr/bin/env bash
set -euo pipefail
grep '^[a-z][a-z]*[0-9]*$' /var/tmp/ec-q036/users.txt > /root/q036-users.txt
