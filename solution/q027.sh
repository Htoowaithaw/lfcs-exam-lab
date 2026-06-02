#!/usr/bin/env bash
set -euo pipefail
cat >/usr/local/bin/q027-status-summary.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
declare -A count=([OK]=0 [WARN]=0 [FAIL]=0)
tail -n +2 /var/tmp/ec-q027/events.csv | while IFS=, read -r _ status; do
  case "$status" in OK|WARN|FAIL) echo "$status" ;; esac
done | awk '{c[$1]++} END{printf "OK=%d\nWARN=%d\nFAIL=%d\n", c["OK"], c["WARN"], c["FAIL"]}' > /root/q027-summary.txt
EOF
chmod 0755 /usr/local/bin/q027-status-summary.sh
