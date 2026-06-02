#!/usr/bin/env bash
set -euo pipefail
cat >/usr/local/bin/q028-process.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
tmp="$(mktemp -d /tmp/q028.XXXXXX)"
cleanup(){ rm -rf "$tmp"; }
trap cleanup EXIT
cp /var/tmp/ec-q028/input.txt "$tmp/input.txt"
tr '[:lower:]' '[:upper:]' < "$tmp/input.txt" > /root/q028-output.txt
EOF
chmod 0755 /usr/local/bin/q028-process.sh
