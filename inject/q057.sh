#!/usr/bin/env bash
set -euo pipefail
rm -rf /var/tmp/ec-q057
mkdir -p /var/tmp/ec-q057/repo
cd /var/tmp/ec-q057/repo
git init -q
git config user.name LFCS
git config user.email lfcs@example.com
printf 'base\n' > app.txt
git add app.txt
git commit -q -m 'initial commit'
printf 'base\nupdated=true\n' > app.txt
