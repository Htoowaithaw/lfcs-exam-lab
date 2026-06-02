#!/usr/bin/env bash
set -euo pipefail
awk -F: '$3 >= 1000 {print $1","$7}' /var/tmp/ec-q041/passwd.sample | sort > /root/q041-users.csv
