#!/usr/bin/env bash
set -euo pipefail
patch -d /etc/ec-q017 app.conf /var/tmp/ec-q017/app.patch
