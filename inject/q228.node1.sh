#!/usr/bin/env bash
set -euo pipefail
rm -f /vagrant/.tmp-q228.pub
rm -rf /root/.ssh/lfcs-q228 /root/.ssh/config
ssh-keygen -R 192.168.56.12 >/dev/null 2>&1 || true
ssh-keygen -R lfcs-node2-4 >/dev/null 2>&1 || true
