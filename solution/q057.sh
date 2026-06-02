#!/usr/bin/env bash
set -euo pipefail
git -C /var/tmp/ec-q057/repo add app.txt
git -C /var/tmp/ec-q057/repo -c user.name=LFCS -c user.email=lfcs@example.com commit -m 'update app config'
