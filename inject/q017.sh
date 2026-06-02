#!/usr/bin/env bash
set -euo pipefail
rm -rf /etc/ec-q017 /var/tmp/ec-q017
mkdir -p /etc/ec-q017 /var/tmp/ec-q017
cat >/etc/ec-q017/app.conf <<'EOF'
port=8080
tls=disabled
log_level=debug
EOF
cat >/var/tmp/ec-q017/app.patch <<'EOF'
--- app.conf.orig
+++ app.conf
@@ -1,3 +1,3 @@
-port=8080
-tls=disabled
-log_level=debug
+port=9443
+tls=enabled
+log_level=info
EOF
