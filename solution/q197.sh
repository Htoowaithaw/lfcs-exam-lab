#!/usr/bin/env bash
set -euo pipefail
echo 'root:LFCSroot123!' | chpasswd
passwd -u root
