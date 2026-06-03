#!/usr/bin/env bash
set -euo pipefail
ip route add 198.51.3.0/24 dev lo metric 3
