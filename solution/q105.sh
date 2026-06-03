#!/usr/bin/env bash
set -euo pipefail
ip link add lfcsnet1 type dummy
ip addr add 10.55.1.10/24 dev lfcsnet1
ip -6 addr add fd00:55:1::10/64 dev lfcsnet1
ip link set lfcsnet1 up
echo '10.55.1.10 phase5d-net1.local' >> /etc/hosts
