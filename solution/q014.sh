#!/usr/bin/env bash
set -euo pipefail
sed -i 's/^environment=.*/environment=production/; s/^debug=.*/debug=false/; s/^workers=.*/workers=4/' /etc/lfcs-q014/app.ini
