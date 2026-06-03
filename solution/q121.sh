#!/usr/bin/env bash
set -euo pipefail
modprobe bonding
ip link add bondlfcs5 type bond mode active-backup
ip link add bnd5a type dummy
ip link add bnd5b type dummy
ip link set bnd5a master bondlfcs5
ip link set bnd5b master bondlfcs5
ip link set bnd5a up
ip link set bnd5b up
ip link set bondlfcs5 up
