#!/usr/bin/env bash
set -euo pipefail
fail(){ echo "RESULT: FAIL - $1"; exit 1; }

report=/root/lfcs-resource-report.txt
[ -f "$report" ] || fail "report file is missing"
[ -s "$report" ] || fail "report file is empty"

owner=$(stat -c '%U:%G' "$report")
[ "$owner" = "root:root" ] || fail "report owner is $owner, expected root:root"
mode=$(stat -c '%a' "$report")
[ "$mode" = "640" ] || fail "report mode is $mode, expected 640"

[ "$(grep -Fx '=== TOP CPU ===' "$report" | wc -l)" -eq 1 ] || fail "TOP CPU section label missing or duplicated"
[ "$(grep -Fx '=== VMSTAT ===' "$report" | wc -l)" -eq 1 ] || fail "VMSTAT section label missing or duplicated"
[ "$(grep -Fx '=== LOAD ===' "$report" | wc -l)" -eq 1 ] || fail "LOAD section label missing or duplicated"

top_line=$(grep -nFx '=== TOP CPU ===' "$report" | cut -d: -f1)
vmstat_line=$(grep -nFx '=== VMSTAT ===' "$report" | cut -d: -f1)
load_line=$(grep -nFx '=== LOAD ===' "$report" | cut -d: -f1)
[ "$top_line" -lt "$vmstat_line" ] || fail "TOP CPU section must appear before VMSTAT"
[ "$vmstat_line" -lt "$load_line" ] || fail "VMSTAT section must appear before LOAD"

top_section=$(sed -n "$((top_line + 1)),$((vmstat_line - 1))p" "$report")
printf '%s\n' "$top_section" | grep -Eq '^[[:space:]]*PID[[:space:]]+PPID[[:space:]]+%CPU[[:space:]]+%MEM[[:space:]]+COMMAND[[:space:]]*$' || fail "ps header does not contain required columns"
printf '%s\n' "$top_section" | awk 'NF >= 5 && $1 ~ /^[0-9]+$/ && $2 ~ /^[0-9]+$/ && $3 ~ /^[0-9.]+$/ && $4 ~ /^[0-9.]+$/ {found=1} END{exit !found}' || fail "TOP CPU section has no process rows"

vmstat_section=$(sed -n "$((vmstat_line + 1)),$((load_line - 1))p" "$report")
printf '%s\n' "$vmstat_section" | grep -Eq '^procs[[:space:]]+-+memory-+' || fail "vmstat procs header missing"
sample_count=$(printf '%s\n' "$vmstat_section" | awk '$1 ~ /^[0-9]+$/ && $2 ~ /^[0-9]+$/ && NF >= 17 {count++} END{print count+0}')
[ "$sample_count" -ge 2 ] || fail "vmstat must include at least two samples"

load_section=$(sed -n "$((load_line + 1)),\$p" "$report")
printf '%s\n' "$load_section" | grep -q 'load average' || fail "uptime load average line missing"

echo "RESULT: PASS"
