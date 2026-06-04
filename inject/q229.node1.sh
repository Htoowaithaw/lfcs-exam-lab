#!/usr/bin/env bash
set -euo pipefail
rm -f /vagrant/.tmp-q229.pub
rm -rf /root/.ssh/lfcs-q229 /root/.ssh/config
ssh-keygen -R 192.168.56.12 >/dev/null 2>&1 || true
ssh-keygen -R lfcs-node2-5 >/dev/null 2>&1 || true
