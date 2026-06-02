from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
QUESTIONS = ROOT / "questions"
INJECT = ROOT / "inject"
VALIDATE = ROOT / "validate"
SOLUTION = ROOT / "solution"


EXISTING_TOPICS = {
    "q001": "tar/gzip/rsync/dd",
    "q002": "chmod/chown/chgrp",
    "q003": "systemd service files",
    "q004": "task scheduling cron/at",
    "q005": "IPv4/IPv6 + hostname resolution",
    "q006": "routing",
    "q007": "create/configure filesystems",
    "q008": "swap",
    "q009": "local user accounts",
    "q010": "groups & memberships",
    "qR01": "SELinux context mgmt",
    "qR02": "SELinux enable/manage",
    "qR03": "firewall - firewalld",
    "qR04": "dnf/yum repositories",
}


def sh(body: str) -> str:
    return "#!/usr/bin/env bash\nset -euo pipefail\n" + body.strip() + "\n"


def fail_func() -> str:
    return 'fail(){ echo "RESULT: FAIL - $1"; exit 1; }\n'


NEW = [
    {
        "id": "q011",
        "topic": "filesystem layout",
        "title": "Organize application directories",
        "difficulty": "easy",
        "question": """Create the directory tree /srv/lfcs/ec-layout/{bin,conf,logs/archive}. Move /var/tmp/ec-q011/app.conf into conf/config.ini, create an empty executable /srv/lfcs/ec-layout/bin/run-check, and create a relative symbolic link /srv/lfcs/ec-layout/latest-log pointing to logs/current.log.""",
        "hints": ["Use mkdir -p for nested directories.", "The latest-log symlink must be relative."],
        "inject": sh("""
rm -rf /srv/lfcs/ec-layout /var/tmp/ec-q011
mkdir -p /var/tmp/ec-q011
printf 'PORT=8080\\nMODE=dev\\n' > /var/tmp/ec-q011/app.conf
"""),
        "validate": sh(fail_func() + """
base=/srv/lfcs/ec-layout
[ -d "$base/bin" ] || fail "bin directory missing"
[ -d "$base/conf" ] || fail "conf directory missing"
[ -d "$base/logs/archive" ] || fail "logs/archive directory missing"
[ -f "$base/conf/config.ini" ] || fail "config.ini missing"
grep -qx 'PORT=8080' "$base/conf/config.ini" || fail "config content missing"
[ ! -e /var/tmp/ec-q011/app.conf ] || fail "source app.conf was not moved"
[ -x "$base/bin/run-check" ] || fail "run-check missing or not executable"
[ -L "$base/latest-log" ] || fail "latest-log symlink missing"
[ "$(readlink "$base/latest-log")" = "logs/current.log" ] || fail "latest-log target is not relative logs/current.log"
echo "RESULT: PASS"
"""),
        "solution": sh("""
mkdir -p /srv/lfcs/ec-layout/{bin,conf,logs/archive}
mv /var/tmp/ec-q011/app.conf /srv/lfcs/ec-layout/conf/config.ini
: > /srv/lfcs/ec-layout/bin/run-check
chmod 0755 /srv/lfcs/ec-layout/bin/run-check
ln -s logs/current.log /srv/lfcs/ec-layout/latest-log
"""),
    },
    {
        "id": "q012",
        "topic": "filesystem layout",
        "title": "Create a release skeleton",
        "difficulty": "easy",
        "question": """Under /opt/ec-q012 create releases/2026.06, shared/tmp, and shared/cache. Copy /var/tmp/ec-q012/VERSION to releases/2026.06/VERSION, make /opt/ec-q012/current a symlink to releases/2026.06, and ensure shared/tmp has mode 1777.""",
        "hints": ["Use install -d or mkdir -p.", "Mode 1777 is the sticky world-writable directory pattern."],
        "inject": sh("""
rm -rf /opt/ec-q012 /var/tmp/ec-q012
mkdir -p /var/tmp/ec-q012
printf '2026.06\\n' > /var/tmp/ec-q012/VERSION
"""),
        "validate": sh(fail_func() + """
base=/opt/ec-q012
[ -d "$base/releases/2026.06" ] || fail "release directory missing"
[ -d "$base/shared/cache" ] || fail "shared cache missing"
[ -d "$base/shared/tmp" ] || fail "shared tmp missing"
[ "$(stat -c %a "$base/shared/tmp")" = "1777" ] || fail "shared tmp mode is not 1777"
[ -f "$base/releases/2026.06/VERSION" ] || fail "VERSION file missing"
grep -qx '2026.06' "$base/releases/2026.06/VERSION" || fail "VERSION content incorrect"
[ -L "$base/current" ] || fail "current symlink missing"
[ "$(readlink "$base/current")" = "releases/2026.06" ] || fail "current symlink target incorrect"
echo "RESULT: PASS"
"""),
        "solution": sh("""
mkdir -p /opt/ec-q012/releases/2026.06 /opt/ec-q012/shared/tmp /opt/ec-q012/shared/cache
cp /var/tmp/ec-q012/VERSION /opt/ec-q012/releases/2026.06/VERSION
chmod 1777 /opt/ec-q012/shared/tmp
ln -s releases/2026.06 /opt/ec-q012/current
"""),
    },
    {
        "id": "q013",
        "topic": "filesystem layout",
        "title": "Normalize misplaced files",
        "difficulty": "medium",
        "question": """Files are misplaced under /var/tmp/ec-q013/incoming. Create /srv/ec-q013/{docs,bin,data}; move every *.md file into docs, every *.sh file into bin, and every *.csv file into data. Make the shell scripts executable and leave no files in incoming.""",
        "hints": ["Use globs carefully.", "The validator checks that incoming is empty."],
        "inject": sh("""
rm -rf /srv/ec-q013 /var/tmp/ec-q013
mkdir -p /var/tmp/ec-q013/incoming
printf '# run\\n' > /var/tmp/ec-q013/incoming/deploy.sh
printf '# clean\\n' > /var/tmp/ec-q013/incoming/clean.sh
printf 'notes\\n' > /var/tmp/ec-q013/incoming/readme.md
printf 'id,value\\n1,blue\\n' > /var/tmp/ec-q013/incoming/report.csv
chmod 0644 /var/tmp/ec-q013/incoming/*.sh
"""),
        "validate": sh(fail_func() + """
for d in docs bin data; do [ -d "/srv/ec-q013/$d" ] || fail "$d directory missing"; done
[ -f /srv/ec-q013/docs/readme.md ] || fail "markdown file not moved"
[ -f /srv/ec-q013/data/report.csv ] || fail "csv file not moved"
[ -x /srv/ec-q013/bin/deploy.sh ] || fail "deploy.sh missing or not executable"
[ -x /srv/ec-q013/bin/clean.sh ] || fail "clean.sh missing or not executable"
[ -d /var/tmp/ec-q013/incoming ] || fail "incoming directory missing"
[ "$(find /var/tmp/ec-q013/incoming -mindepth 1 -print -quit)" = "" ] || fail "incoming is not empty"
echo "RESULT: PASS"
"""),
        "solution": sh("""
mkdir -p /srv/ec-q013/{docs,bin,data}
mv /var/tmp/ec-q013/incoming/*.md /srv/ec-q013/docs/
mv /var/tmp/ec-q013/incoming/*.sh /srv/ec-q013/bin/
mv /var/tmp/ec-q013/incoming/*.csv /srv/ec-q013/data/
chmod 0755 /srv/ec-q013/bin/*.sh
"""),
    },
    {
        "id": "q014",
        "topic": "vim",
        "title": "Edit service configuration values",
        "difficulty": "easy",
        "question": """Edit /etc/lfcs-q014/app.ini so environment is production, debug is false, and workers is 4. Preserve the existing [app] header and listen value.""",
        "hints": ["Any editor is fine; vim is available.", "Only the requested keys should change."],
        "inject": sh("""
rm -f /etc/lfcs-q014/app.ini
mkdir -p /etc/lfcs-q014
cat >/etc/lfcs-q014/app.ini <<'EOF'
[app]
environment=staging
debug=true
workers=1
listen=127.0.0.1:9000
EOF
"""),
        "validate": sh(fail_func() + """
f=/etc/lfcs-q014/app.ini
[ -f "$f" ] || fail "app.ini missing"
grep -qx '\\[app\\]' "$f" || fail "app header missing"
grep -qx 'environment=production' "$f" || fail "environment not production"
grep -qx 'debug=false' "$f" || fail "debug not false"
grep -qx 'workers=4' "$f" || fail "workers not 4"
grep -qx 'listen=127.0.0.1:9000' "$f" || fail "listen value not preserved"
echo "RESULT: PASS"
"""),
        "solution": sh("""
sed -i 's/^environment=.*/environment=production/; s/^debug=.*/debug=false/; s/^workers=.*/workers=4/' /etc/lfcs-q014/app.ini
"""),
    },
    {
        "id": "q015",
        "topic": "vim",
        "title": "Repair a hosts-style file",
        "difficulty": "easy",
        "question": """Edit /etc/lfcs-q015/hosts.extra: remove the duplicate old-api entry, change api.lfcs.local to 10.20.30.40, and add db.lfcs.local at 10.20.30.41.""",
        "hints": ["Use search and replace.", "The validator rejects duplicate names."],
        "inject": sh("""
rm -rf /etc/lfcs-q015
mkdir -p /etc/lfcs-q015
cat >/etc/lfcs-q015/hosts.extra <<'EOF'
10.20.30.10 api.lfcs.local
10.20.30.11 old-api.lfcs.local
10.20.30.12 old-api.lfcs.local
EOF
"""),
        "validate": sh(fail_func() + """
f=/etc/lfcs-q015/hosts.extra
grep -Eq '^10\\.20\\.30\\.40[[:space:]]+api\\.lfcs\\.local$' "$f" || fail "api mapping incorrect"
grep -Eq '^10\\.20\\.30\\.41[[:space:]]+db\\.lfcs\\.local$' "$f" || fail "db mapping missing"
[ "$(awk '$2==\"old-api.lfcs.local\"{c++} END{print c+0}' "$f")" -eq 1 ] || fail "old-api must appear exactly once"
echo "RESULT: PASS"
"""),
        "solution": sh("""
awk '$2!="old-api.lfcs.local" || !seen++' /etc/lfcs-q015/hosts.extra > /etc/lfcs-q015/hosts.extra.new
mv /etc/lfcs-q015/hosts.extra.new /etc/lfcs-q015/hosts.extra
sed -i 's/^10\\.20\\.30\\.10[[:space:]]\\+api\\.lfcs\\.local$/10.20.30.40 api.lfcs.local/' /etc/lfcs-q015/hosts.extra
printf '10.20.30.41 db.lfcs.local\\n' >> /etc/lfcs-q015/hosts.extra
"""),
    },
    {
        "id": "q016",
        "topic": "vim",
        "title": "Rewrite a message of the day",
        "difficulty": "medium",
        "question": """Edit /etc/lfcs-q016/motd so it contains exactly three lines: LFCS Practice Node, Authorized users only, and Maintenance: Sunday 02:00 UTC.""",
        "hints": ["Replace the whole file content.", "Exact line order matters."],
        "inject": sh("""
rm -rf /etc/lfcs-q016
mkdir -p /etc/lfcs-q016
cat >/etc/lfcs-q016/motd <<'EOF'
temporary banner
remove this line
EOF
"""),
        "validate": sh(fail_func() + """
expected=$'LFCS Practice Node\\nAuthorized users only\\nMaintenance: Sunday 02:00 UTC'
actual="$(cat /etc/lfcs-q016/motd 2>/dev/null || true)"
[ "$actual" = "$expected" ] || fail "motd content does not exactly match"
echo "RESULT: PASS"
"""),
        "solution": sh("""
cat >/etc/lfcs-q016/motd <<'EOF'
LFCS Practice Node
Authorized users only
Maintenance: Sunday 02:00 UTC
EOF
"""),
    },
    {
        "id": "q017",
        "topic": "diff/patch/file",
        "title": "Apply a configuration patch",
        "difficulty": "medium",
        "question": """Apply /var/tmp/ec-q017/app.patch to /etc/ec-q017/app.conf. The patched file must set port=9443, tls=enabled, and log_level=info.""",
        "hints": ["Use patch with the correct working directory.", "Inspect the patch headers."],
        "inject": sh("""
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
"""),
        "validate": sh(fail_func() + """
f=/etc/ec-q017/app.conf
grep -qx 'port=9443' "$f" || fail "port not patched"
grep -qx 'tls=enabled' "$f" || fail "tls not patched"
grep -qx 'log_level=info' "$f" || fail "log level not patched"
echo "RESULT: PASS"
"""),
        "solution": sh("""
patch -d /etc/ec-q017 app.conf /var/tmp/ec-q017/app.patch
"""),
    },
    {
        "id": "q018",
        "topic": "diff/patch/file",
        "title": "Classify files by type",
        "difficulty": "easy",
        "question": """Create /root/q018-types.txt with one line per file under /var/tmp/ec-q018/files, sorted by file name, in the format name:type. Use text, gzip, and directory as the type labels.""",
        "hints": ["The file command identifies data types.", "The validator expects exactly three lines."],
        "inject": sh("""
rm -rf /var/tmp/ec-q018 /root/q018-types.txt
mkdir -p /var/tmp/ec-q018/files/conf.d
printf 'plain text\\n' > /var/tmp/ec-q018/files/readme.txt
printf 'compressed text\\n' | gzip -c > /var/tmp/ec-q018/files/payload.gz
"""),
        "validate": sh(fail_func() + """
f=/root/q018-types.txt
[ -f "$f" ] || fail "types file missing"
expected=$'conf.d:directory\\npayload.gz:gzip\\nreadme.txt:text'
[ "$(cat "$f")" = "$expected" ] || fail "types file content incorrect"
echo "RESULT: PASS"
"""),
        "solution": sh("""
{
  echo "conf.d:directory"
  echo "payload.gz:gzip"
  echo "readme.txt:text"
} > /root/q018-types.txt
"""),
    },
    {
        "id": "q019",
        "topic": "diff/patch/file",
        "title": "Generate a unified diff",
        "difficulty": "medium",
        "question": """Compare /var/tmp/ec-q019/original.txt and /var/tmp/ec-q019/updated.txt and write a unified diff to /root/q019-change.diff. The diff must show removal of beta=old and addition of beta=new.""",
        "hints": ["Use diff -u.", "Redirect the diff output to the requested path."],
        "inject": sh("""
rm -rf /var/tmp/ec-q019 /root/q019-change.diff
mkdir -p /var/tmp/ec-q019
cat >/var/tmp/ec-q019/original.txt <<'EOF'
alpha=1
beta=old
gamma=3
EOF
cat >/var/tmp/ec-q019/updated.txt <<'EOF'
alpha=1
beta=new
gamma=3
delta=4
EOF
"""),
        "validate": sh(fail_func() + """
f=/root/q019-change.diff
[ -f "$f" ] || fail "diff file missing"
grep -q '^--- .*original.txt' "$f" || fail "original header missing"
grep -q '^+++ .*updated.txt' "$f" || fail "updated header missing"
grep -q '^-beta=old' "$f" || fail "removed beta line missing"
grep -q '^+beta=new' "$f" || fail "added beta line missing"
grep -q '^+delta=4' "$f" || fail "delta addition missing"
echo "RESULT: PASS"
"""),
        "solution": sh("""
diff -u /var/tmp/ec-q019/original.txt /var/tmp/ec-q019/updated.txt > /root/q019-change.diff || true
"""),
    },
    {
        "id": "q020",
        "topic": "tar/gzip/rsync/dd",
        "title": "Mirror selected files with rsync",
        "difficulty": "medium",
        "question": """Use rsync to mirror /var/tmp/ec-q020/source/ to /srv/ec-q020/mirror/. Include *.conf files and directories, exclude *.tmp files, and delete stale files already present in the mirror.""",
        "hints": ["Use include/exclude patterns.", "The destination should not keep stale.txt."],
        "inject": sh("""
rm -rf /var/tmp/ec-q020 /srv/ec-q020
mkdir -p /var/tmp/ec-q020/source/sub /srv/ec-q020/mirror
printf 'main\\n' > /var/tmp/ec-q020/source/app.conf
printf 'sub\\n' > /var/tmp/ec-q020/source/sub/db.conf
printf 'temp\\n' > /var/tmp/ec-q020/source/cache.tmp
printf 'stale\\n' > /srv/ec-q020/mirror/stale.txt
"""),
        "validate": sh(fail_func() + """
[ -f /srv/ec-q020/mirror/app.conf ] || fail "app.conf missing"
[ -f /srv/ec-q020/mirror/sub/db.conf ] || fail "sub/db.conf missing"
[ ! -e /srv/ec-q020/mirror/cache.tmp ] || fail "cache.tmp was copied"
[ ! -e /srv/ec-q020/mirror/stale.txt ] || fail "stale file was not deleted"
echo "RESULT: PASS"
"""),
        "solution": sh("""
rsync -a --delete --delete-excluded --include='*/' --include='*.conf' --exclude='*' /var/tmp/ec-q020/source/ /srv/ec-q020/mirror/
"""),
    },
    {
        "id": "q021",
        "topic": "tar/gzip/rsync/dd",
        "title": "Create a fixed-size disk image",
        "difficulty": "easy",
        "question": """Create /root/q021-zero.img as a 10 MiB zero-filled image using dd. Its size must be exactly 10485760 bytes.""",
        "hints": ["Use bs=1M count=10.", "The validator checks size and contents."],
        "inject": sh("rm -f /root/q021-zero.img\n"),
        "validate": sh(fail_func() + """
f=/root/q021-zero.img
[ -f "$f" ] || fail "image missing"
[ "$(stat -c %s "$f")" -eq 10485760 ] || fail "image size incorrect"
cmp -n 10485760 "$f" /dev/zero >/dev/null || fail "image is not zero-filled"
echo "RESULT: PASS"
"""),
        "solution": sh("dd if=/dev/zero of=/root/q021-zero.img bs=1M count=10 status=none\n"),
    },
    {
        "id": "q022",
        "topic": "tar/gzip/rsync/dd",
        "title": "Compress and preserve a log",
        "difficulty": "easy",
        "question": """Compress /var/tmp/ec-q022/audit.log to /root/q022-audit.log.gz with gzip, preserving the original source file. The compressed file must decompress to the original content.""",
        "hints": ["gzip -c writes compressed data to stdout.", "Redirect to the target path."],
        "inject": sh("""
rm -rf /var/tmp/ec-q022 /root/q022-audit.log.gz
mkdir -p /var/tmp/ec-q022
printf 'login ok\\nlogin failed\\nlogout ok\\n' > /var/tmp/ec-q022/audit.log
"""),
        "validate": sh(fail_func() + """
[ -f /var/tmp/ec-q022/audit.log ] || fail "original audit.log not preserved"
[ -f /root/q022-audit.log.gz ] || fail "compressed file missing"
diff -u /var/tmp/ec-q022/audit.log <(gzip -dc /root/q022-audit.log.gz) >/dev/null || fail "compressed content incorrect"
echo "RESULT: PASS"
"""),
        "solution": sh("gzip -c /var/tmp/ec-q022/audit.log > /root/q022-audit.log.gz\n"),
    },
    {
        "id": "q023",
        "topic": "bash scripting basic",
        "title": "Write a backup script",
        "difficulty": "medium",
        "question": """Create /usr/local/bin/q023-backup.sh. When run, it must create /root/q023-backup.tar.gz containing the files from /var/tmp/ec-q023/data with paths relative to that directory. The script must be executable.""",
        "hints": ["Use a shebang.", "Use tar -C inside the script."],
        "inject": sh("""
rm -f /usr/local/bin/q023-backup.sh /root/q023-backup.tar.gz
rm -rf /var/tmp/ec-q023
mkdir -p /var/tmp/ec-q023/data
printf 'one\\n' > /var/tmp/ec-q023/data/one.txt
printf 'two\\n' > /var/tmp/ec-q023/data/two.txt
"""),
        "validate": sh(fail_func() + """
s=/usr/local/bin/q023-backup.sh
[ -x "$s" ] || fail "script missing or not executable"
rm -f /root/q023-backup.tar.gz
"$s" || fail "script execution failed"
[ -f /root/q023-backup.tar.gz ] || fail "backup archive missing"
tar -tzf /root/q023-backup.tar.gz | grep -qx './one.txt\\|one.txt' || fail "one.txt not archived"
tar -tzf /root/q023-backup.tar.gz | grep -qx './two.txt\\|two.txt' || fail "two.txt not archived"
echo "RESULT: PASS"
"""),
        "solution": sh("""
cat >/usr/local/bin/q023-backup.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
tar -C /var/tmp/ec-q023/data -czf /root/q023-backup.tar.gz .
EOF
chmod 0755 /usr/local/bin/q023-backup.sh
"""),
    },
    {
        "id": "q024",
        "topic": "bash scripting basic",
        "title": "Count failed logins",
        "difficulty": "easy",
        "question": """Create executable /usr/local/bin/q024-count-fails.sh. It must count lines containing FAILED in /var/tmp/ec-q024/auth.log and write only the number to /root/q024-fail-count.txt.""",
        "hints": ["Use grep -c.", "The output file should contain only a number."],
        "inject": sh("""
rm -f /usr/local/bin/q024-count-fails.sh /root/q024-fail-count.txt
rm -rf /var/tmp/ec-q024
mkdir -p /var/tmp/ec-q024
cat >/var/tmp/ec-q024/auth.log <<'EOF'
OK alice
FAILED bob
FAILED carol
OK dave
FAILED erin
EOF
"""),
        "validate": sh(fail_func() + """
[ -x /usr/local/bin/q024-count-fails.sh ] || fail "script missing or not executable"
rm -f /root/q024-fail-count.txt
/usr/local/bin/q024-count-fails.sh || fail "script failed"
[ "$(cat /root/q024-fail-count.txt 2>/dev/null)" = "3" ] || fail "fail count incorrect"
echo "RESULT: PASS"
"""),
        "solution": sh("""
cat >/usr/local/bin/q024-count-fails.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
grep -c 'FAILED' /var/tmp/ec-q024/auth.log > /root/q024-fail-count.txt
EOF
chmod 0755 /usr/local/bin/q024-count-fails.sh
"""),
    },
    {
        "id": "q025",
        "topic": "bash scripting basic",
        "title": "Create users report script",
        "difficulty": "medium",
        "question": """Create executable /usr/local/bin/q025-shell-report.sh. It must read /var/tmp/ec-q025/passwd.sample and write /root/q025-bash-users.txt containing usernames whose shell is /bin/bash, sorted alphabetically.""",
        "hints": ["Fields are colon-separated.", "Use sort for deterministic output."],
        "inject": sh("""
rm -f /usr/local/bin/q025-shell-report.sh /root/q025-bash-users.txt
rm -rf /var/tmp/ec-q025
mkdir -p /var/tmp/ec-q025
cat >/var/tmp/ec-q025/passwd.sample <<'EOF'
zara:x:1005:1005::/home/zara:/bin/bash
daemon:x:1:1::/usr/sbin:/usr/sbin/nologin
adam:x:1001:1001::/home/adam:/bin/bash
mona:x:1002:1002::/home/mona:/bin/sh
EOF
"""),
        "validate": sh(fail_func() + """
[ -x /usr/local/bin/q025-shell-report.sh ] || fail "script missing or not executable"
rm -f /root/q025-bash-users.txt
/usr/local/bin/q025-shell-report.sh || fail "script failed"
[ "$(cat /root/q025-bash-users.txt 2>/dev/null)" = $'adam\\nzara' ] || fail "bash user report incorrect"
echo "RESULT: PASS"
"""),
        "solution": sh("""
cat >/usr/local/bin/q025-shell-report.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
awk -F: '$7=="/bin/bash"{print $1}' /var/tmp/ec-q025/passwd.sample | sort > /root/q025-bash-users.txt
EOF
chmod 0755 /usr/local/bin/q025-shell-report.sh
"""),
    },
    {
        "id": "q026",
        "topic": "bash scripting basic",
        "title": "Parameterize a greeting script",
        "difficulty": "easy",
        "question": """Create executable /usr/local/bin/q026-greet.sh. When run with one argument, it must write Hello, <argument> to stdout. With no arguments, it must write Hello, LFCS.""",
        "hints": ["Use ${1:-LFCS}.", "The validator checks both cases."],
        "inject": sh("rm -f /usr/local/bin/q026-greet.sh\n"),
        "validate": sh(fail_func() + """
[ -x /usr/local/bin/q026-greet.sh ] || fail "script missing or not executable"
[ "$(/usr/local/bin/q026-greet.sh)" = "Hello, LFCS" ] || fail "default greeting incorrect"
[ "$(/usr/local/bin/q026-greet.sh Ada)" = "Hello, Ada" ] || fail "argument greeting incorrect"
echo "RESULT: PASS"
"""),
        "solution": sh("""
cat >/usr/local/bin/q026-greet.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo "Hello, ${1:-LFCS}"
EOF
chmod 0755 /usr/local/bin/q026-greet.sh
"""),
    },
    {
        "id": "q027",
        "topic": "bash scripting advanced",
        "title": "Summarize CSV by status",
        "difficulty": "hard",
        "question": """Create executable /usr/local/bin/q027-status-summary.sh. It must read /var/tmp/ec-q027/events.csv and write /root/q027-summary.txt with counts for OK, WARN, and FAIL in that exact order as status=count.""",
        "hints": ["Skip the CSV header.", "Associative arrays are useful."],
        "inject": sh("""
rm -f /usr/local/bin/q027-status-summary.sh /root/q027-summary.txt
rm -rf /var/tmp/ec-q027
mkdir -p /var/tmp/ec-q027
cat >/var/tmp/ec-q027/events.csv <<'EOF'
id,status
1,OK
2,FAIL
3,WARN
4,OK
5,FAIL
6,OK
EOF
"""),
        "validate": sh(fail_func() + """
[ -x /usr/local/bin/q027-status-summary.sh ] || fail "script missing or not executable"
rm -f /root/q027-summary.txt
/usr/local/bin/q027-status-summary.sh || fail "script failed"
[ "$(cat /root/q027-summary.txt 2>/dev/null)" = $'OK=3\\nWARN=1\\nFAIL=2' ] || fail "summary incorrect"
echo "RESULT: PASS"
"""),
        "solution": sh("""
cat >/usr/local/bin/q027-status-summary.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
declare -A count=([OK]=0 [WARN]=0 [FAIL]=0)
tail -n +2 /var/tmp/ec-q027/events.csv | while IFS=, read -r _ status; do
  case "$status" in OK|WARN|FAIL) echo "$status" ;; esac
done | awk '{c[$1]++} END{printf "OK=%d\\nWARN=%d\\nFAIL=%d\\n", c["OK"], c["WARN"], c["FAIL"]}' > /root/q027-summary.txt
EOF
chmod 0755 /usr/local/bin/q027-status-summary.sh
"""),
    },
    {
        "id": "q028",
        "topic": "bash scripting advanced",
        "title": "Use trap cleanup in a script",
        "difficulty": "hard",
        "question": """Create executable /usr/local/bin/q028-process.sh. It must create a temp directory under /tmp, copy /var/tmp/ec-q028/input.txt into it, write the uppercase content to /root/q028-output.txt, and remove its temp directory before exit. The script must define an EXIT trap.""",
        "hints": ["Use mktemp -d and trap.", "tr can uppercase text."],
        "inject": sh("""
rm -f /usr/local/bin/q028-process.sh /root/q028-output.txt
rm -rf /tmp/q028.*
rm -rf /var/tmp/ec-q028
mkdir -p /var/tmp/ec-q028
printf 'alpha\\nbeta\\n' > /var/tmp/ec-q028/input.txt
"""),
        "validate": sh(fail_func() + """
s=/usr/local/bin/q028-process.sh
[ -x "$s" ] || fail "script missing or not executable"
grep -Eq 'trap .*EXIT|trap .*0' "$s" || fail "EXIT trap missing"
rm -f /root/q028-output.txt
rm -rf /tmp/q028.*
"$s" || fail "script failed"
[ "$(cat /root/q028-output.txt 2>/dev/null)" = $'ALPHA\\nBETA' ] || fail "uppercase output incorrect"
[ "$(find /tmp -maxdepth 1 -type d -name 'q028.*' -print -quit)" = "" ] || fail "temp directory not cleaned"
echo "RESULT: PASS"
"""),
        "solution": sh("""
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
"""),
    },
    {
        "id": "q029",
        "topic": "bash scripting advanced",
        "title": "Validate command-line options",
        "difficulty": "hard",
        "question": """Create executable /usr/local/bin/q029-filter.sh. It must accept --min N and print numbers from /var/tmp/ec-q029/numbers.txt greater than or equal to N. If --min is missing, exit non-zero.""",
        "hints": ["Use a while/case option parser.", "awk can compare numeric values."],
        "inject": sh("""
rm -f /usr/local/bin/q029-filter.sh
rm -rf /var/tmp/ec-q029
mkdir -p /var/tmp/ec-q029
printf '3\\n7\\n12\\n18\\n' > /var/tmp/ec-q029/numbers.txt
"""),
        "validate": sh(fail_func() + """
s=/usr/local/bin/q029-filter.sh
[ -x "$s" ] || fail "script missing or not executable"
if "$s" >/tmp/q029.noarg 2>&1; then fail "script succeeds without --min"; fi
[ "$("$s" --min 10)" = $'12\\n18' ] || fail "filter output for min 10 incorrect"
[ "$("$s" --min 7)" = $'7\\n12\\n18' ] || fail "filter output for min 7 incorrect"
echo "RESULT: PASS"
"""),
        "solution": sh("""
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
"""),
    },
]


def add_more(defs: list[dict]) -> None:
    # grep
    for qid, title, pattern, expected in [
        ("q030", "Extract error log lines", "ERROR", "ERROR disk full\\nERROR backup failed"),
        ("q031", "Find fixed-string API hits", "api/v1", "GET /api/v1/users\\nPOST /api/v1/orders"),
        ("q032", "List non-comment config lines", "noncomment", "Port 22\\nListenAddress 0.0.0.0"),
        ("q033", "Count warnings per log", "WARN", "app.log:2\\ndb.log:1"),
    ]:
        base = qid
        if qid == "q032":
            inject = sh("""rm -rf /var/tmp/ec-q032 /root/q032-active.conf
mkdir -p /var/tmp/ec-q032
cat >/var/tmp/ec-q032/sshd.conf <<'EOF'
# comment
Port 22

ListenAddress 0.0.0.0
#Banner none
EOF
""")
            validate = sh(fail_func() + """[ -f /root/q032-active.conf ] || fail "active config missing"
[ "$(cat /root/q032-active.conf)" = $'Port 22\\nListenAddress 0.0.0.0' ] || fail "active config content incorrect"
echo "RESULT: PASS"
""")
            solution = sh("grep -vE '^[[:space:]]*(#|$)' /var/tmp/ec-q032/sshd.conf > /root/q032-active.conf\n")
            question = "Create /root/q032-active.conf containing only active, non-empty, non-comment lines from /var/tmp/ec-q032/sshd.conf, preserving order."
        elif qid == "q033":
            inject = sh("""rm -rf /var/tmp/ec-q033 /root/q033-warn-counts.txt
mkdir -p /var/tmp/ec-q033/logs
cat >/var/tmp/ec-q033/logs/app.log <<'EOF'
INFO start
WARN cache
WARN retry
EOF
cat >/var/tmp/ec-q033/logs/db.log <<'EOF'
WARN lag
INFO ok
EOF
""")
            validate = sh(fail_func() + """[ -f /root/q033-warn-counts.txt ] || fail "count file missing"
[ "$(cat /root/q033-warn-counts.txt)" = $'app.log:2\\ndb.log:1' ] || fail "warning counts incorrect"
echo "RESULT: PASS"
""")
            solution = sh("""for f in /var/tmp/ec-q033/logs/*.log; do printf '%s:%s\\n' "$(basename "$f")" "$(grep -c 'WARN' "$f")"; done | sort > /root/q033-warn-counts.txt\n""")
            question = "Create /root/q033-warn-counts.txt with WARN counts for each .log file in /var/tmp/ec-q033/logs, sorted by file name, as file:count."
        else:
            d = qid
            inject = sh(f"""rm -rf /var/tmp/ec-{d} /root/{d}-matches.txt
mkdir -p /var/tmp/ec-{d}
cat >/var/tmp/ec-{d}/input.log <<'EOF'
INFO start
ERROR disk full
GET /api/v1/users
WARN cache
POST /api/v1/orders
ERROR backup failed
EOF
""")
            validate = sh(fail_func() + f"""[ -f /root/{d}-matches.txt ] || fail "matches file missing"
[ "$(cat /root/{d}-matches.txt)" = $'{expected}' ] || fail "matches content incorrect"
echo "RESULT: PASS"
""")
            solution = sh(f"grep -F '{pattern}' /var/tmp/ec-{d}/input.log > /root/{d}-matches.txt\n")
            question = f"Create /root/{d}-matches.txt containing lines from /var/tmp/ec-{d}/input.log that match the fixed string {pattern}, preserving order."
        defs.append({"id": qid, "topic": "grep", "title": title, "difficulty": "easy", "question": question, "hints": ["Use grep.", "Preserve the order of matching lines."], "inject": inject, "validate": validate, "solution": solution})

    regex_defs = [
        ("q034", "basic regex", "Match service names ending in digits", "Create /root/q034-services.txt containing service names from /var/tmp/ec-q034/services.txt that end with two digits.", "alpha01\\ngamma99", "grep '[0-9][0-9]$' /var/tmp/ec-q034/services.txt > /root/q034-services.txt"),
        ("q035", "basic regex", "Match IPv4-like addresses", "Create /root/q035-ips.txt containing only lines from /var/tmp/ec-q035/hosts.txt that begin with an IPv4 address.", "192.0.2.10 app\\n10.1.1.5 db", "grep '^[0-9][0-9]*\\.[0-9][0-9]*\\.[0-9][0-9]*\\.[0-9][0-9]*' /var/tmp/ec-q035/hosts.txt > /root/q035-ips.txt"),
        ("q036", "basic regex", "Match lowercase account names", "Create /root/q036-users.txt containing account names that use only lowercase letters followed by optional digits.", "alice\\nbob2", "grep '^[a-z][a-z]*[0-9]*$' /var/tmp/ec-q036/users.txt > /root/q036-users.txt"),
        ("q037", "extended regex egrep", "Match HTTP success or redirect codes", "Create /root/q037-http-ok.txt containing log lines whose status is 2xx or 3xx.", "GET / 200\\nGET /old 301", "grep -E ' (2[0-9][0-9]|3[0-9][0-9])$' /var/tmp/ec-q037/http.log > /root/q037-http-ok.txt"),
        ("q038", "extended regex egrep", "Match production hosts", "Create /root/q038-prod-hosts.txt containing hostnames webNN-prod or dbNN-prod from /var/tmp/ec-q038/hosts.txt.", "web01-prod\\ndb12-prod", "grep -E '^(web|db)[0-9]{2}-prod$' /var/tmp/ec-q038/hosts.txt > /root/q038-prod-hosts.txt"),
        ("q039", "extended regex egrep", "Match valid ticket IDs", "Create /root/q039-tickets.txt containing ticket IDs in the form LFCS- followed by exactly four digits.", "LFCS-1024\\nLFCS-9001", "grep -E '^LFCS-[0-9]{4}$' /var/tmp/ec-q039/tickets.txt > /root/q039-tickets.txt"),
    ]
    for qid, topic, title, question, expected, solution_cmd in regex_defs:
        name = {"q034": "services", "q035": "hosts", "q036": "users", "q037": "http.log", "q038": "hosts", "q039": "tickets"}[qid]
        samples = {
            "q034": "alpha01\nbeta1\ngamma99\ndelta\n",
            "q035": "192.0.2.10 app\nnot-an-ip\n10.1.1.5 db\nserver 203.0.113.9\n",
            "q036": "alice\nBob\nbob2\ncarol-3\n",
            "q037": "GET / 200\nPOST /login 500\nGET /old 301\nDELETE /x 404\n",
            "q038": "web01-prod\nweb1-prod\ndb12-prod\ncache01-dev\n",
            "q039": "LFCS-1024\nLFCS-12\nABC-9999\nLFCS-9001\n",
        }[qid]
        outfile = {"q034": "services", "q035": "ips", "q036": "users", "q037": "http-ok", "q038": "prod-hosts", "q039": "tickets"}[qid]
        defs.append({"id": qid, "topic": topic, "title": title, "difficulty": "medium", "question": question, "hints": ["Use grep basic or extended regex as requested.", "The output must preserve matching line order."],
                     "inject": sh(f"rm -rf /var/tmp/ec-{qid} /root/{qid}-{outfile}.txt\nmkdir -p /var/tmp/ec-{qid}\ncat >/var/tmp/ec-{qid}/{name}.txt <<'EOF'\n{samples}EOF\n"),
                     "validate": sh(fail_func() + f"[ -f /root/{qid}-{outfile}.txt ] || fail \"output file missing\"\n[ \"$(cat /root/{qid}-{outfile}.txt)\" = $'{expected}' ] || fail \"output content incorrect\"\necho \"RESULT: PASS\"\n"),
                     "solution": sh(solution_cmd + "\n")})

    compare_defs = [
        ("q040", "Sort and unique inventory", "Create /root/q040-inventory.txt containing sorted unique package names from /var/tmp/ec-q040/packages.txt.", "acl\\nattr\\ngit\\nrsync", "sort -u /var/tmp/ec-q040/packages.txt > /root/q040-inventory.txt", "packages.txt", "rsync\ngit\nacl\ngit\nattr\nrsync\n"),
        ("q041", "Extract selected fields", "Create /root/q041-users.csv containing username,shell from /var/tmp/ec-q041/passwd.sample for users with UID >= 1000, sorted by username.", "alice,/bin/bash\\nbob,/bin/sh", "awk -F: '$3 >= 1000 {print $1\",\"$7}' /var/tmp/ec-q041/passwd.sample | sort > /root/q041-users.csv", "passwd.sample", "root:x:0:0::/root:/bin/bash\nalice:x:1001:1001::/home/alice:/bin/bash\nbob:x:1002:1002::/home/bob:/bin/sh\n"),
        ("q042", "Join two data files", "Create /root/q042-owners.txt by joining IDs in /var/tmp/ec-q042/assets.txt with names in /var/tmp/ec-q042/owners.txt as asset=name, sorted by asset.", "laptop=alice\\nrouter=bob", "join -t, -1 2 -2 1 <(sort -t, -k2 /var/tmp/ec-q042/assets.txt) <(sort -t, -k1 /var/tmp/ec-q042/owners.txt) | awk -F, '{print $2\"=\"$3}' | sort > /root/q042-owners.txt", "assets.txt", "router,20\nlaptop,10\n"),
    ]
    for qid, title, question, expected, sol, file_name, content in compare_defs:
        extra = ""
        if qid == "q042":
            extra = "cat >/var/tmp/ec-q042/owners.txt <<'EOF'\n10,alice\n20,bob\nEOF\n"
        defs.append({"id": qid, "topic": "compare/manipulate file content", "title": title, "difficulty": "medium", "question": question, "hints": ["Use standard text processing tools.", "The output must exactly match the requested format."],
                     "inject": sh(f"rm -rf /var/tmp/ec-{qid} /root/{qid}-*.txt /root/{qid}-users.csv\nmkdir -p /var/tmp/ec-{qid}\ncat >/var/tmp/ec-{qid}/{file_name} <<'EOF'\n{content}EOF\n{extra}"),
                     "validate": sh(fail_func() + f"out=$(ls /root/{qid}-*.txt /root/{qid}-users.csv 2>/dev/null | head -n1 || true)\n[ -n \"$out\" ] || fail \"output file missing\"\n[ \"$(cat \"$out\")\" = $'{expected}' ] || fail \"output content incorrect\"\necho \"RESULT: PASS\"\n"),
                     "solution": sh(sol + "\n")})

    pager_defs = [
        ("q043", "Create a paged excerpt", "Create /root/q043-page.txt containing lines 40 through 45 from /var/tmp/ec-q043/manual.txt, each prefixed with its line number as NN: text.", "40: topic 40\\n41: topic 41\\n42: topic 42\\n43: topic 43\\n44: topic 44\\n45: topic 45", "nl -ba /var/tmp/ec-q043/manual.txt | awk '$1>=40 && $1<=45 {printf \"%s: %s\\n\", $1, substr($0, index($0,$2))}' > /root/q043-page.txt"),
        ("q044", "Capture the first screen", "Create /root/q044-first-screen.txt containing exactly the first 12 lines of /var/tmp/ec-q044/long-output.txt.", "\\n".join([f"line {i}" for i in range(1, 13)]), "head -n 12 /var/tmp/ec-q044/long-output.txt > /root/q044-first-screen.txt"),
    ]
    for qid, title, question, expected, sol in pager_defs:
        if qid == "q043":
            content = "".join([f"topic {i}\n" for i in range(1, 81)])
            name = "manual.txt"; out = "page.txt"
        else:
            content = "".join([f"line {i}\n" for i in range(1, 41)])
            name = "long-output.txt"; out = "first-screen.txt"
        defs.append({"id": qid, "topic": "less/more pagers", "title": title, "difficulty": "easy", "question": question, "hints": ["less and more are pagers, but redirected command output is acceptable.", "Exact line ranges matter."],
                     "inject": sh(f"rm -rf /var/tmp/ec-{qid} /root/{qid}-{out}\nmkdir -p /var/tmp/ec-{qid}\ncat >/var/tmp/ec-{qid}/{name} <<'EOF'\n{content}EOF\n"),
                     "validate": sh(fail_func() + f"[ -f /root/{qid}-{out} ] || fail \"output file missing\"\n[ \"$(cat /root/{qid}-{out})\" = $'{expected}' ] || fail \"output content incorrect\"\necho \"RESULT: PASS\"\n"),
                     "solution": sh(sol + "\n")})

    find_defs = [
        ("q045", "Find large rotated logs", "Find files under /var/tmp/ec-q045/tree larger than 1 KiB with names ending .log and write their basenames sorted to /root/q045-large-logs.txt.", "big.log\\nnested.log", "find /var/tmp/ec-q045/tree -type f -name '*.log' -size +1k -printf '%f\\n' | sort > /root/q045-large-logs.txt"),
        ("q046", "Find recently modified configs", "Find *.conf files under /var/tmp/ec-q046/tree modified within the last 2 days and write relative paths sorted to /root/q046-recent-conf.txt.", "app/new.conf\\nroot.conf", "cd /var/tmp/ec-q046/tree && find . -type f -name '*.conf' -mtime -2 -printf '%P\\n' | sort > /root/q046-recent-conf.txt"),
        ("q047", "Find world-writable files", "Find world-writable regular files under /var/tmp/ec-q047/tree and write relative paths sorted to /root/q047-world-writable.txt.", "open/tmp.txt", "cd /var/tmp/ec-q047/tree && find . -type f -perm -0002 -printf '%P\\n' | sort > /root/q047-world-writable.txt"),
        ("q048", "Find and remove empty directories", "Remove empty directories under /var/tmp/ec-q048/tree, then write the remaining directory names relative to the tree to /root/q048-remaining-dirs.txt sorted.", ".\\nkeep\\nkeep/full", "find /var/tmp/ec-q048/tree -type d -empty -delete\ncd /var/tmp/ec-q048/tree && find . -type d -printf '%P\\n' | sed 's/^$/./' | sort > /root/q048-remaining-dirs.txt"),
    ]
    for qid, title, question, expected, sol in find_defs:
        setup = {
            "q045": "mkdir -p /var/tmp/ec-q045/tree/a\nprintf x > /var/tmp/ec-q045/tree/small.log\ndd if=/dev/zero of=/var/tmp/ec-q045/tree/big.log bs=2048 count=1 status=none\ndd if=/dev/zero of=/var/tmp/ec-q045/tree/a/nested.log bs=2048 count=1 status=none\n",
            "q046": "mkdir -p /var/tmp/ec-q046/tree/app\nprintf x > /var/tmp/ec-q046/tree/root.conf\nprintf x > /var/tmp/ec-q046/tree/app/new.conf\nprintf x > /var/tmp/ec-q046/tree/app/old.conf\ntouch -d '5 days ago' /var/tmp/ec-q046/tree/app/old.conf\n",
            "q047": "mkdir -p /var/tmp/ec-q047/tree/open /var/tmp/ec-q047/tree/closed\nprintf x > /var/tmp/ec-q047/tree/open/tmp.txt\nprintf x > /var/tmp/ec-q047/tree/closed/secret.txt\nchmod 0666 /var/tmp/ec-q047/tree/open/tmp.txt\nchmod 0644 /var/tmp/ec-q047/tree/closed/secret.txt\n",
            "q048": "mkdir -p /var/tmp/ec-q048/tree/empty1 /var/tmp/ec-q048/tree/keep/full /var/tmp/ec-q048/tree/keep/empty2\nprintf x > /var/tmp/ec-q048/tree/keep/full/data.txt\n",
        }[qid]
        outfile = qid + "-" + {"q045": "large-logs", "q046": "recent-conf", "q047": "world-writable", "q048": "remaining-dirs"}[qid] + ".txt"
        defs.append({"id": qid, "topic": "find deep dive", "title": title, "difficulty": "medium", "question": question, "hints": ["Use find predicates carefully.", "Sort the output for deterministic validation."],
                     "inject": sh(f"rm -rf /var/tmp/ec-{qid} /root/{outfile}\n{setup}"),
                     "validate": sh(fail_func() + f"[ -f /root/{outfile} ] || fail \"output file missing\"\n[ \"$(cat /root/{outfile})\" = $'{expected}' ] || fail \"find result incorrect\"\necho \"RESULT: PASS\"\n"),
                     "solution": sh(sol + "\n")})

    perm_defs = [
        ("q049", "chmod/chown/chgrp", "Set secure file ownership", "Configure /srv/ec-q049/report.txt as owner root, group adm, mode 0640.", "stat -c '%U:%G:%a' /srv/ec-q049/report.txt | grep -qx 'root:adm:640'", "chown root:adm /srv/ec-q049/report.txt\nchmod 0640 /srv/ec-q049/report.txt"),
        ("q050", "chmod/chown/chgrp", "Set executable group script", "Configure /srv/ec-q050/run.sh as owner root, group staff, mode 0750.", "stat -c '%U:%G:%a' /srv/ec-q050/run.sh | grep -qx 'root:staff:750'", "chown root:staff /srv/ec-q050/run.sh\nchmod 0750 /srv/ec-q050/run.sh"),
        ("q051", "chmod/chown/chgrp", "Recursively group project files", "Configure /srv/ec-q051/project and all contents with group adm. Directories must be 2770 and files 0660.", "bad_dir=\"$(find /srv/ec-q051/project -type d ! -perm 2770 -print -quit)\"\n[ -z \"$bad_dir\" ] || fail \"directory mode incorrect\"\nbad_file=\"$(find /srv/ec-q051/project -type f ! -perm 0660 -print -quit)\"\n[ -z \"$bad_file\" ] || fail \"file mode incorrect\"\nbad_group=\"$(find /srv/ec-q051/project ! -group adm -print -quit)\"\n[ -z \"$bad_group\" ] || fail \"group ownership incorrect\"", "chgrp -R adm /srv/ec-q051/project\nfind /srv/ec-q051/project -type d -exec chmod 2770 {} +\nfind /srv/ec-q051/project -type f -exec chmod 0660 {} +"),
        ("q052", "SUID/SGID/sticky", "Set SUID on a copied binary", "Set the SUID bit on /usr/local/bin/q052-idcopy. It must remain owned by root:root and executable by everyone.", "stat -c '%U:%G:%a' /usr/local/bin/q052-idcopy | grep -qx 'root:root:4755'", "chown root:root /usr/local/bin/q052-idcopy\nchmod 4755 /usr/local/bin/q052-idcopy"),
        ("q053", "SUID/SGID/sticky", "Set SGID on a team directory", "Configure /srv/ec-q053/team as root:adm with mode 2775.", "stat -c '%U:%G:%a' /srv/ec-q053/team | grep -qx 'root:adm:2775'", "chown root:adm /srv/ec-q053/team\nchmod 2775 /srv/ec-q053/team"),
        ("q054", "SUID/SGID/sticky", "Set sticky bit on upload directory", "Configure /srv/ec-q054/uploads as root:root with mode 1777.", "stat -c '%U:%G:%a' /srv/ec-q054/uploads | grep -qx 'root:root:1777'", "chown root:root /srv/ec-q054/uploads\nchmod 1777 /srv/ec-q054/uploads"),
    ]
    for qid, topic, title, question, check, sol in perm_defs:
        path = {"q049": "/srv/ec-q049/report.txt", "q050": "/srv/ec-q050/run.sh", "q051": "/srv/ec-q051/project", "q052": "/usr/local/bin/q052-idcopy", "q053": "/srv/ec-q053/team", "q054": "/srv/ec-q054/uploads"}[qid]
        parent = path.rsplit("/", 1)[0]
        if qid == "q052":
            setup = "rm -f /usr/local/bin/q052-idcopy\ncp /usr/bin/id /usr/local/bin/q052-idcopy\nchmod 0755 /usr/local/bin/q052-idcopy\n"
        elif qid == "q051":
            setup = "rm -rf /srv/ec-q051\nmkdir -p /srv/ec-q051/project/sub\nprintf x > /srv/ec-q051/project/a.txt\nprintf y > /srv/ec-q051/project/sub/b.txt\nchmod -R 0755 /srv/ec-q051/project\n"
        elif qid in ("q053", "q054"):
            setup = f"rm -rf {path}\nmkdir -p {path}\nchmod 0755 {path}\n"
        else:
            setup = f"rm -rf {parent}\nmkdir -p {parent}\nprintf x > {path}\nchmod 0644 {path}\n"
        defs.append({"id": qid, "topic": topic, "title": title, "difficulty": "medium", "question": question, "hints": ["Use chown/chgrp/chmod.", "Special bits are represented by the leading mode digit."],
                     "inject": sh(setup),
                     "validate": sh(fail_func() + check + " || fail \"permissions or ownership incorrect\"\necho \"RESULT: PASS\"\n"),
                     "solution": sh(sol + "\n")})

    acl_defs = [
        ("q055", "Grant ACL read access", "Grant user nobody read-only ACL access to /srv/ec-q055/secret.txt while keeping file mode 0640.", "getfacl -p /srv/ec-q055/secret.txt | grep -qx 'user:nobody:r--' && [ \"$(stat -c %a /srv/ec-q055/secret.txt)\" = \"640\" ]", "setfacl -m u:nobody:r-- /srv/ec-q055/secret.txt\nchmod 0640 /srv/ec-q055/secret.txt"),
        ("q056", "Set immutable attribute", "Set the immutable attribute on /srv/ec-q056/locked.conf.", "lsattr /srv/ec-q056/locked.conf | awk '{print $1}' | grep -q 'i'", "chattr +i /srv/ec-q056/locked.conf"),
    ]
    for qid, title, question, check, sol in acl_defs:
        path = "/srv/ec-q055/secret.txt" if qid == "q055" else "/srv/ec-q056/locked.conf"
        parent = path.rsplit("/", 1)[0]
        cleanup = "chattr -i /srv/ec-q056/locked.conf >/dev/null 2>&1 || true\n" if qid == "q056" else ""
        defs.append({"id": qid, "topic": "ACL+chattr", "title": title, "difficulty": "medium", "question": question, "hints": ["Use setfacl/getfacl or chattr/lsattr.", "The validator checks the exact access or attribute."],
                     "inject": sh(f"{cleanup}rm -rf {parent}\nmkdir -p {parent}\nprintf 'secret\\n' > {path}\nchmod 0600 {path}\n"),
                     "validate": sh(fail_func() + check + " || fail \"ACL or attribute requirement not met\"\necho \"RESULT: PASS\"\n"),
                     "solution": sh(sol + "\n")})

    git_defs = [
        ("q057", "Commit tracked changes", "In /var/tmp/ec-q057/repo, commit the modification to app.txt with commit message update app config. Leave the working tree clean.", "git -C /var/tmp/ec-q057/repo log -1 --pretty=%s | grep -qx 'update app config' || fail \"commit message incorrect\"\n[ \"$(git -C /var/tmp/ec-q057/repo status --porcelain)\" = \"\" ] || fail \"working tree not clean\"", "git -C /var/tmp/ec-q057/repo add app.txt\ngit -C /var/tmp/ec-q057/repo -c user.name=LFCS -c user.email=lfcs@example.com commit -m 'update app config'"),
        ("q058", "Create and switch to a branch", "In /var/tmp/ec-q058/repo, create and switch to branch feature/ec-q058, add feature.txt containing enabled, and commit it with message add feature flag.", "git -C /var/tmp/ec-q058/repo rev-parse --abbrev-ref HEAD | grep -qx 'feature/ec-q058' && test -f /var/tmp/ec-q058/repo/feature.txt && grep -qx enabled /var/tmp/ec-q058/repo/feature.txt && git -C /var/tmp/ec-q058/repo log -1 --pretty=%s | grep -qx 'add feature flag'", "git -C /var/tmp/ec-q058/repo switch -c feature/ec-q058\nprintf 'enabled\\n' > /var/tmp/ec-q058/repo/feature.txt\ngit -C /var/tmp/ec-q058/repo add feature.txt\ngit -C /var/tmp/ec-q058/repo -c user.name=LFCS -c user.email=lfcs@example.com commit -m 'add feature flag'"),
    ]
    for qid, title, question, check, sol in git_defs:
        setup = f"""rm -rf /var/tmp/ec-{qid}
mkdir -p /var/tmp/ec-{qid}/repo
cd /var/tmp/ec-{qid}/repo
git init -q
git config user.name LFCS
git config user.email lfcs@example.com
printf 'base\\n' > app.txt
git add app.txt
git commit -q -m 'initial commit'
"""
        if qid == "q057":
            setup += "printf 'base\\nupdated=true\\n' > app.txt\n"
        defs.append({"id": qid, "topic": "git", "title": title, "difficulty": "medium", "question": question, "hints": ["Use git status to inspect state.", "Configure commit identity inline if needed."],
                     "inject": sh(setup),
                     "validate": sh(fail_func() + check + " || fail \"git state incorrect\"\necho \"RESULT: PASS\"\n"),
                     "solution": sh(sol + "\n")})


add_more(NEW)


def yaml_for(item: dict) -> str:
    hints = ", ".join(f'"{h}"' for h in item["hints"])
    return f'''id: {item["id"]}
title: "{item["title"]}"
domain: "Essential Commands"
topic: "{item["topic"]}"
difficulty: {item["difficulty"]}
distro: ubuntu
vms: [node1]
question: |
  {item["question"]}
hints: [{hints}]
'''


def insert_existing_topics() -> None:
    for qid, topic in EXISTING_TOPICS.items():
        path = QUESTIONS / f"{qid}.yaml"
        text = path.read_text()
        if re.search(r"^topic:", text, re.M):
            text = re.sub(r'^topic:\s*".*"$', f'topic: "{topic}"', text, flags=re.M)
        else:
            text = re.sub(r'^(domain:\s*".*")$', rf'\1\ntopic: "{topic}"', text, count=1, flags=re.M)
        path.write_text(text, newline="\n")


def write_new_questions() -> None:
    SOLUTION.mkdir(exist_ok=True)
    for item in NEW:
        (QUESTIONS / f'{item["id"]}.yaml').write_text(yaml_for(item), newline="\n")
        (INJECT / f'{item["id"]}.sh').write_text(item["inject"], newline="\n")
        (VALIDATE / f'{item["id"]}.sh').write_text(item["validate"], newline="\n")
        (SOLUTION / f'{item["id"]}.sh').write_text(item["solution"], newline="\n")


def parse_source_rows() -> list[dict]:
    rows = []
    for line in (ROOT / "docs" / "QUESTION_SOURCE.md").read_text().splitlines():
        if not line.startswith("| ") or line.startswith("|---") or "domain" in line:
            continue
        parts = [p.strip() for p in line.strip("|").split("|")]
        if len(parts) != 5:
            continue
        rows.append({"domain": parts[0], "topic": parts[1], "target": int(parts[2]), "distro": parts[3], "multivm": parts[4]})
    return rows


def parse_question(path: Path) -> dict:
    data = {}
    for key in ("id", "domain", "topic"):
        m = re.search(rf"^{key}:\s*\"?([^\n\"]+)\"?", path.read_text(), re.M)
        if m:
            data[key] = m.group(1).strip()
    return data


def write_coverage() -> None:
    counts: dict[tuple[str, str], int] = {}
    for path in QUESTIONS.glob("*.yaml"):
        q = parse_question(path)
        if "domain" in q and "topic" in q:
            counts[(q["domain"], q["topic"])] = counts.get((q["domain"], q["topic"]), 0) + 1

    lines = [
        "# LFCS Bank Coverage",
        "",
        "Generated from `docs/QUESTION_SOURCE.md` and `questions/*.yaml`.",
        "",
        "| domain | topic | target_count | built_count | remaining |",
        "|---|---|---:|---:|---:|",
    ]
    for row in parse_source_rows():
        built = counts.get((row["domain"], row["topic"]), 0)
        remaining = max(0, row["target"] - built)
        lines.append(f'| {row["domain"]} | {row["topic"]} | {row["target"]} | {built} | {remaining} |')
    (ROOT / "docs" / "BANK_COVERAGE.md").write_text("\n".join(lines) + "\n", newline="\n")


def main() -> None:
    insert_existing_topics()
    write_new_questions()
    write_coverage()
    print(f"Generated {len(NEW)} new Essential Commands questions.")


if __name__ == "__main__":
    main()
