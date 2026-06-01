#!/usr/bin/env bash
set -euo pipefail
cp /etc/hosts /etc/hosts.lfcs-q005.bak
sed -i '/repo\.lfcs\.local/d' /etc/hosts
