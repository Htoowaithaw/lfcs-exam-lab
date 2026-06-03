#!/usr/bin/env bash
set -euo pipefail
ip link add lfcsnet2 type dummy
ip addr add 10.55.2.10/24 dev lfcsnet2
ip -6 addr add fd00:55:2::10/64 dev lfcsnet2
ip link set lfcsnet2 up
echo '10.55.2.10 phase5d-net2.local' >> /etc/hosts
