#!/usr/bin/env bash
set -euo pipefail
cat >/usr/local/bin/q026-greet.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo "Hello, ${1:-LFCS}"
EOF
chmod 0755 /usr/local/bin/q026-greet.sh
