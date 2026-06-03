#!/usr/bin/env bash
set -euo pipefail
{ echo LSBLK; lsblk; echo DF; df -h; echo READAHEAD; blockdev --getra /dev/sdb; } > /root/lfcs-storage-perf3.txt
