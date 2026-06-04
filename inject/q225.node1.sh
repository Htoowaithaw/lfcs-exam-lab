#!/usr/bin/env bash
set -euo pipefail
rm -f /vagrant/.tmp-q225.pub
rm -rf /root/.ssh/lfcs-q225 /root/.ssh/config
ssh-keygen -R 192.168.56.12 >/dev/null 2>&1 || true
ssh-keygen -R lfcs-node2-1 >/dev/null 2>&1 || true
