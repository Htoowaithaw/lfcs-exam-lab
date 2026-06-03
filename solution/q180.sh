#!/usr/bin/env bash
set -euo pipefail
groupadd lfcsteam2
useradd -m grpuser2
usermod -aG lfcsteam2 grpuser2
