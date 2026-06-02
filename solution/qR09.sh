#!/usr/bin/env bash
set -euo pipefail
setenforce 1
setsebool -P virt_use_nfs on
