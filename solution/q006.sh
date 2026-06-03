#!/usr/bin/env bash
set -euo pipefail
ip route replace 203.0.113.0/24 via 10.0.2.2
