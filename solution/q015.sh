#!/usr/bin/env bash
set -euo pipefail
awk '$2!="old-api.lfcs.local" || !seen++' /etc/lfcs-q015/hosts.extra > /etc/lfcs-q015/hosts.extra.new
mv /etc/lfcs-q015/hosts.extra.new /etc/lfcs-q015/hosts.extra
sed -i 's/^10\.20\.30\.10[[:space:]]\+api\.lfcs\.local$/10.20.30.40 api.lfcs.local/' /etc/lfcs-q015/hosts.extra
printf '10.20.30.41 db.lfcs.local\n' >> /etc/lfcs-q015/hosts.extra
