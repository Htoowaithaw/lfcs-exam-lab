#!/usr/bin/env bash
set -euo pipefail
rm -rf /var/tmp/ec-q048 /root/q048-remaining-dirs.txt
mkdir -p /var/tmp/ec-q048/tree/empty1 /var/tmp/ec-q048/tree/keep/full /var/tmp/ec-q048/tree/keep/empty2
printf x > /var/tmp/ec-q048/tree/keep/full/data.txt
