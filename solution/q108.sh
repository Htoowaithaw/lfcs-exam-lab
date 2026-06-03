#!/usr/bin/env bash
set -euo pipefail
ip link add lfcsnet4 type dummy
ip addr add 10.55.4.10/24 dev lfcsnet4
ip -6 addr add fd00:55:4::10/64 dev lfcsnet4
ip link set lfcsnet4 up
echo '10.55.4.10 phase5d-net4.local' >> /etc/hosts
