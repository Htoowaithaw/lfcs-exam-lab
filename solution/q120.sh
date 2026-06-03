#!/usr/bin/env bash
set -euo pipefail
modprobe bonding
ip link add bondlfcs4 type bond mode active-backup
ip link add bnd4a type dummy
ip link add bnd4b type dummy
ip link set bnd4a master bondlfcs4
ip link set bnd4b master bondlfcs4
ip link set bnd4a up
ip link set bnd4b up
ip link set bondlfcs4 up
