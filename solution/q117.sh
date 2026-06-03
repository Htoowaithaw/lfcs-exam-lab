#!/usr/bin/env bash
set -euo pipefail
ip link add brlfcs1 type bridge
ip link add brd1a type dummy
ip link add brd1b type dummy
ip link set brd1a master brlfcs1
ip link set brd1b master brlfcs1
ip link set brd1a up
ip link set brd1b up
ip link set brlfcs1 up
