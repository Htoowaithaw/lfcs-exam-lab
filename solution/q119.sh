#!/usr/bin/env bash
set -euo pipefail
ip link add brlfcs3 type bridge
ip link add brd3a type dummy
ip link add brd3b type dummy
ip link set brd3a master brlfcs3
ip link set brd3b master brlfcs3
ip link set brd3a up
ip link set brd3b up
ip link set brlfcs3 up
