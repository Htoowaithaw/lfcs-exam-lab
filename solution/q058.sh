#!/usr/bin/env bash
set -euo pipefail
git -C /var/tmp/ec-q058/repo switch -c feature/ec-q058
printf 'enabled\n' > /var/tmp/ec-q058/repo/feature.txt
git -C /var/tmp/ec-q058/repo add feature.txt
git -C /var/tmp/ec-q058/repo -c user.name=LFCS -c user.email=lfcs@example.com commit -m 'add feature flag'
