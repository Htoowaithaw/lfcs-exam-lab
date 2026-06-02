#!/usr/bin/env bash
set -euo pipefail
cat > /etc/apparmor.d/usr.local.bin.lfcs-op-aa3 <<'EOF'
#include <tunables/global>

/usr/local/bin/lfcs-op-aa3 {
  #include <abstractions/base>
  /etc/hostname r,
  /usr/bin/cat ix,
}
EOF
apparmor_parser -r /etc/apparmor.d/usr.local.bin.lfcs-op-aa3
