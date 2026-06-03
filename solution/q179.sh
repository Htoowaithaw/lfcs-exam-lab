#!/usr/bin/env bash
set -euo pipefail
groupadd lfcsteam1
useradd -m grpuser1
usermod -aG lfcsteam1 grpuser1
