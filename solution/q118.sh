#!/usr/bin/env bash
set -euo pipefail
ip link add brlfcs2 type bridge
ip link add brd2a type dummy
ip link add brd2b type dummy
ip link set brd2a master brlfcs2
ip link set brd2b master brlfcs2
ip link set brd2a up
ip link set brd2b up
ip link set brlfcs2 up
