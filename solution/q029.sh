#!/usr/bin/env bash
set -euo pipefail
cat >/usr/local/bin/q029-filter.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
min=""
while [ $# -gt 0 ]; do
  case "$1" in
    --min) min="${2:-}"; shift 2 ;;
    *) exit 2 ;;
  esac
done
[ -n "$min" ] || exit 2
awk -v min="$min" '$1 >= min' /var/tmp/ec-q029/numbers.txt
EOF
chmod 0755 /usr/local/bin/q029-filter.sh
