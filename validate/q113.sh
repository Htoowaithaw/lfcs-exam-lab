#!/usr/bin/env bash
set -euo pipefail
if ! test -s /run/lfcs-ss2.pid; then echo "RESULT: FAIL - PID file missing"; exit 1; fi
if ! kill -0 $(cat /run/lfcs-ss2.pid); then echo "RESULT: FAIL - listener PID is not running"; exit 1; fi
if ! ss -ltn sport = :18102 | grep -q '127.0.0.1:18102'; then echo "RESULT: FAIL - port is not listening on loopback"; exit 1; fi
echo "RESULT: PASS"
