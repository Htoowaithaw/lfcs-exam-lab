#!/usr/bin/env bash
set -euo pipefail
groupadd lfcsteam3
useradd -m grpuser3
usermod -aG lfcsteam3 grpuser3
