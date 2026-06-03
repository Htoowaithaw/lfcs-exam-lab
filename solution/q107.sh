#!/usr/bin/env bash
set -euo pipefail
ip link add lfcsnet3 type dummy
ip addr add 10.55.3.10/24 dev lfcsnet3
ip -6 addr add fd00:55:3::10/64 dev lfcsnet3
ip link set lfcsnet3 up
echo '10.55.3.10 phase5d-net3.local' >> /etc/hosts
