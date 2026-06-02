from __future__ import annotations

import gzip
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def sh(lines: list[str]) -> str:
    return "#!/usr/bin/env bash\nset -euo pipefail\n" + "\n".join(lines) + "\n"


def fail_check(cond: str, reason: str) -> str:
    return f'if ! {cond}; then echo "RESULT: FAIL - {reason}"; exit 1; fi'


def write(qid: str, title: str, topic: str, distro: str, question: str, hints: list[str],
          inject: list[str], validate: list[str], solution: list[str], difficulty: str = "medium") -> None:
    vm = "lfcs-rocky1" if distro == "rocky" else "node1"
    yaml = "\n".join([
        f"id: {qid}",
        f'title: "{title}"',
        'domain: "Operations & Deployment"',
        f'topic: "{topic}"',
        f"difficulty: {difficulty}",
        f"distro: {distro}",
        f"vms: [{vm}]",
        "question: |",
        *[f"  {line}" for line in question.strip().splitlines()],
        "hints: " + json.dumps(hints),
        "",
    ])
    (ROOT / "questions" / f"{qid}.yaml").write_text(yaml, encoding="utf-8")
    (ROOT / "inject" / f"{qid}.sh").write_text(sh(inject), encoding="utf-8", newline="\n")
    checked = []
    for i, command in enumerate(validate, 1):
        reason = command.replace("\\", "\\\\").replace("$", "\\$").replace("`", "\\`").replace('"', "'")
        checked.append(f'if ! {command}; then echo "RESULT: FAIL - check {i} failed: {reason}"; exit 1; fi')
    (ROOT / "validate" / f"{qid}.sh").write_text(sh(checked + ['echo "RESULT: PASS"']), encoding="utf-8", newline="\n")
    (ROOT / "solution" / f"{qid}.sh").write_text(sh(solution), encoding="utf-8", newline="\n")


def systemd(qid: str, n: int, name: str) -> None:
    script = f"/usr/local/bin/{name}.sh"
    svc = f"{name}.service"
    ready = f"/run/{name}.ready"
    write(qid, f"Repair {name} systemd service", "systemd service files", "ubuntu",
          f"""A service named {name} is installed but does not meet the requested state.
Fix /etc/systemd/system/{svc} so it runs {script}, creates {ready}, is active now, and is enabled at boot.""",
          ["Run daemon-reload after editing unit files.", "Validate active and enabled state with systemctl."],
          [
              f"cat > {script} <<'EOF'\n#!/usr/bin/env bash\nmkdir -p /run\necho ready > {ready}\nsleep infinity\nEOF",
              f"chmod 0755 {script}",
              f"cat > /etc/systemd/system/{svc} <<'EOF'\n[Unit]\nDescription=Broken LFCS service {qid}\nAfter=network.target\n\n[Service]\nType=simple\nExecStart=/usr/local/bin/{name}-wrong.sh\nRestart=no\n\n[Install]\nWantedBy=multi-user.target\nEOF",
              f"systemctl disable --now {name}.service >/dev/null 2>&1 || true",
              "systemctl daemon-reload",
              f"rm -f {ready}",
          ],
          [
              f"systemctl is-enabled --quiet {name}.service",
              f"systemctl is-active --quiet {name}.service",
              f"grep -q '^ExecStart={script}$' /etc/systemd/system/{svc}",
              f"test -s {ready}",
          ],
          [
              f"python3 - <<'PY'\nfrom pathlib import Path\np=Path('/etc/systemd/system/{svc}')\ns=p.read_text()\ns=s.replace('/usr/local/bin/{name}-wrong.sh','{script}')\np.write_text(s)\nPY",
              "systemctl daemon-reload",
              f"systemctl enable --now {name}.service",
          ])


def process(qid: str, n: int, name: str) -> None:
    pidfile = f"/run/{name}.pid"
    ans = f"/root/{name}.answer"
    write(qid, f"Control process state for {name}", "process management", "ubuntu",
          f"""A long-running process for {name} was started during setup.
Find the PID recorded in {pidfile}, renice it to {n}, and write the PID to {ans}. The process must remain running.""",
          ["Use ps, renice, and kill -0.", "The PID file identifies the exact process."],
          [
              f"nohup bash -c 'exec sleep 3600' >/tmp/{name}.out 2>&1 &",
              f"echo $! > {pidfile}",
              f"rm -f {ans}",
          ],
          [
              f"test -s {ans}",
              f"pid=$(cat {ans})",
              f"test \"$pid\" = \"$(cat {pidfile})\"",
              "kill -0 \"$pid\"",
              f"test \"$(ps -o ni= -p \"$pid\" | tr -d ' ')\" = \"{n}\"",
          ],
          [
              f"pid=$(cat {pidfile})",
              f"renice -n {n} -p \"$pid\" >/dev/null",
              f"echo \"$pid\" > {ans}",
          ])


def logging(qid: str, n: int, name: str) -> None:
    target = f"/var/log/{name}.log"
    tag = f"{name}-tag"
    write(qid, f"Route syslog messages for {name}", "logging rsyslog+journald", "ubuntu",
          f"""Configure rsyslog so messages tagged {tag} are written to {target}.
Reload rsyslog and record one test message containing LFCS-{n} in that file.""",
          ["A tag match rule can route logger messages.", "Use systemctl reload-or-restart rsyslog."],
          [
              f"rm -f /etc/rsyslog.d/{name}.conf {target}",
              "systemctl enable --now rsyslog >/dev/null 2>&1 || true",
              "systemctl restart rsyslog >/dev/null 2>&1 || true",
          ],
          [
              f"test -f /etc/rsyslog.d/{name}.conf",
              "rsyslogd -N1 >/dev/null 2>&1",
              f"test -s {target}",
              f"grep -q 'LFCS-{n}' {target}",
          ],
          [
              f"cat > /etc/rsyslog.d/{name}.conf <<'EOF'\nif $programname == '{tag}' then {target}\n& stop\nEOF",
              "systemctl reload-or-restart rsyslog",
              f"logger -t {tag} 'LFCS-{n}'",
              "sleep 1",
          ])


def cron(qid: str, n: int, name: str) -> None:
    cronfile = f"/etc/cron.d/{name}"
    out = f"/var/tmp/{name}.stamp"
    write(qid, f"Install scheduled task {name}", "task scheduling cron/at", "ubuntu",
          f"""Create a root cron entry in {cronfile} that runs every {n} minutes and writes the literal text {name}-ok to {out}.
Use a valid /etc/cron.d format with an explicit user field.""",
          ["Files in /etc/cron.d need mode 0644.", "Include the user column."],
          [f"rm -f {cronfile} {out}"],
          [
              f"test -f {cronfile}",
              f"test \"$(stat -c %a {cronfile})\" = \"644\"",
              f"grep -Eq '^\\*/{n} \\* \\* \\* \\* root /bin/sh -c .+{out}' {cronfile}",
          ],
          [
              f"cat > {cronfile} <<'EOF'\n*/{n} * * * * root /bin/sh -c 'echo {name}-ok > {out}'\nEOF",
              f"chmod 0644 {cronfile}",
          ])


def apt_repo(qid: str, n: int, name: str) -> None:
    repo = f"/etc/apt/sources.list.d/{name}.list"
    write(qid, f"Use offline apt repository {name}", "apt repositories", "ubuntu",
          f"""Configure apt to use the local file repository at /opt/lfcs-apt-repo.
Create {repo}, update metadata without using the internet, and install package lfcs-apt-tool.""",
          ["Use a file: repository with trusted=yes.", "The package is already staged in the base image."],
          [
              "apt-get purge -y lfcs-apt-tool >/dev/null 2>&1 || true",
              f"rm -f {repo}",
              "rm -rf /var/lib/apt/lists/*lfcs-apt-repo*",
          ],
          [
              f"test -f {repo}",
              f"grep -q 'file:/opt/lfcs-apt-repo' {repo}",
              "dpkg -s lfcs-apt-tool >/dev/null 2>&1",
              "command -v lfcs-apt-tool >/dev/null 2>&1",
          ],
          [
              f"cat > {repo} <<'EOF'\ndeb [trusted=yes] file:/opt/lfcs-apt-repo ./\nEOF",
              "apt-get update -o Dir::Etc::sourcelist='sources.list.d/" + name + ".list' -o Dir::Etc::sourceparts='-' -o APT::Get::List-Cleanup='0'",
              "apt-get install -y --no-install-recommends lfcs-apt-tool",
          ])


def compile_src(qid: str, n: int, name: str) -> None:
    write(qid, f"Build staged source package {name}", "compile from source", "ubuntu",
          f"""Build the staged source tarball /opt/lfcs-src/lfcs-hello-1.0.tar.gz.
Install the program as /usr/local/bin/{name} and make it print LFCS-COMPILED-{n}.""",
          ["Extract the tarball under /usr/local/src.", "Use make install with BINARY and MESSAGE variables."],
          [f"rm -rf /usr/local/src/{name} /usr/local/bin/{name}"],
          [
              f"test -x /usr/local/bin/{name}",
              f"test \"$(/usr/local/bin/{name})\" = \"LFCS-COMPILED-{n}\"",
          ],
          [
              f"mkdir -p /usr/local/src/{name}",
              f"tar -xzf /opt/lfcs-src/lfcs-hello-1.0.tar.gz -C /usr/local/src/{name} --strip-components=1",
              f"sed -i 's/echo lfcs-hello/echo LFCS-COMPILED-{n}/' /usr/local/src/{name}/Makefile",
              f"make -C /usr/local/src/{name}",
              f"install -m 0755 /usr/local/src/{name}/lfcs-hello /usr/local/bin/{name}",
          ])


def resource(qid: str, n: int, name: str) -> None:
    out = f"/root/{name}.txt"
    write(qid, f"Capture resource data for {name}", "resource monitoring", "ubuntu",
          f"""Capture a process and memory snapshot into {out}.
The file must include a ps header with PID, a vmstat header, and the current system load average line from uptime.""",
          ["Use ps, vmstat, and uptime.", "The validator checks the artifact, not your terminal output."],
          [f"rm -f {out}"],
          [
              f"test -s {out}",
              f"grep -Eq 'PID|COMMAND' {out}",
              f"grep -q 'procs' {out}",
              f"grep -q 'load average' {out}",
          ],
          [
              f"{{ ps -eo pid,ppid,ni,comm --sort=-%cpu | head -n {n}; vmstat 1 2; uptime; }} > {out}",
          ])


def sysctl_q(qid: str, key: str, value: str, name: str) -> None:
    conf = f"/etc/sysctl.d/{name}.conf"
    write(qid, f"Set sysctl {key}", "sysctl", "ubuntu",
          f"""Set {key} to {value} immediately and persistently using {conf}.
The runtime value and the persistent file must both match.""",
          ["Use sysctl -w for runtime.", "Use sysctl --system or sysctl -p for persistence."],
          [f"rm -f {conf}", f"sysctl -w {key}=0 >/dev/null 2>&1 || true"],
          [
              f"test \"$(sysctl -n {key})\" = \"{value}\"",
              f"test -f {conf}",
              f"grep -Eq '^{re.escape(key)}[[:space:]]*=[[:space:]]*{value}$' {conf}",
          ],
          [
              f"cat > {conf} <<'EOF'\n{key} = {value}\nEOF",
              f"sysctl -w {key}={value}",
          ])


def apparmor(qid: str, n: int, name: str) -> None:
    binp = f"/usr/local/bin/{name}"
    prof = f"/etc/apparmor.d/usr.local.bin.{name}"
    write(qid, f"Load AppArmor profile {name}", "AppArmor", "ubuntu",
          f"""Create and load an enforcing AppArmor profile for {binp}.
The profile must allow basic read-only access and appear in aa-status.""",
          ["Use apparmor_parser -r.", "Profile names normally follow the executable path."],
          [
              f"cat > {binp} <<'EOF'\n#!/usr/bin/env bash\ncat /etc/hostname\nEOF",
              f"chmod 0755 {binp}",
              f"apparmor_parser -R {prof} >/dev/null 2>&1 || true",
              f"rm -f {prof}",
          ],
          [
              f"test -f {prof}",
              f"apparmor_parser -Q {prof} >/dev/null 2>&1",
              f"aa-status 2>/dev/null | grep -Fq '{binp}'",
          ],
          [
              f"cat > {prof} <<'EOF'\n#include <tunables/global>\n\n{binp} {{\n  #include <abstractions/base>\n  /etc/hostname r,\n  /usr/bin/cat ix,\n}}\nEOF",
              f"apparmor_parser -r {prof}",
          ])


def docker_q(qid: str, n: int, name: str) -> None:
    img = f"lfcs/{name}:1.0"
    cname = f"{name}-ctr"
    write(qid, f"Build and run local Docker image {name}", "docker", "ubuntu",
          f"""Using only the preloaded image lfcs-local-base:1.0, build image {img} from /root/{name}/Dockerfile.
Run a detached container named {cname} with label lfcs.question={qid}.""",
          ["Do not pull from a remote registry.", "Use docker inspect to verify labels."],
          [
              "systemctl enable --now docker >/dev/null 2>&1 || true",
              f"docker rm -f {cname} >/dev/null 2>&1 || true",
              f"docker rmi -f {img} >/dev/null 2>&1 || true",
              f"rm -rf /root/{name}",
              f"mkdir -p /root/{name}",
              f"cat > /root/{name}/Dockerfile <<'EOF'\nFROM lfcs-local-base:1.0\nLABEL lfcs.seed=wrong\nCMD [\"/bin/busybox\", \"sleep\", \"3600\"]\nEOF",
          ],
          [
              f"docker image inspect {img} >/dev/null 2>&1",
              f"docker ps --format '{{{{.Names}}}}' | grep -Fxq {cname}",
              f"test \"$(docker inspect -f '{{{{ index .Config.Labels \"lfcs.question\" }}}}' {cname})\" = \"{qid}\"",
          ],
          [
              f"cat > /root/{name}/Dockerfile <<'EOF'\nFROM lfcs-local-base:1.0\nLABEL lfcs.question={qid}\nCMD [\"/bin/busybox\", \"sleep\", \"3600\"]\nEOF",
              f"docker build -t {img} /root/{name}",
              f"docker run -d --name {cname} --label lfcs.question={qid} {img}",
          ])


def virsh_q(qid: str, n: int, name: str) -> None:
    xml = f"/root/{name}.xml"
    pool = f"{name}-pool"
    write(qid, f"Define libvirt resources {name}", "KVM/virsh", "ubuntu",
          f"""Define a libvirt domain named {name} from {xml}; do not boot it.
Also define, start, and autostart a dir storage pool named {pool} at /var/lib/libvirt/{pool}.""",
          ["Use virsh define, pool-define-as, pool-start, and pool-autostart.", "Validation uses dumpxml and pool-info only."],
          [
              "systemctl enable --now libvirtd >/dev/null 2>&1 || true",
              f"virsh undefine {name} >/dev/null 2>&1 || true",
              f"virsh pool-destroy {pool} >/dev/null 2>&1 || true",
              f"virsh pool-undefine {pool} >/dev/null 2>&1 || true",
              f"mkdir -p /var/lib/libvirt/{pool}",
              f"cat > {xml} <<'EOF'\n<domain type='qemu'>\n  <name>{name}</name>\n  <memory unit='MiB'>{256+n}</memory>\n  <vcpu>{1+n%2}</vcpu>\n  <os><type arch='x86_64'>hvm</type></os>\n</domain>\nEOF",
          ],
          [
              f"virsh dominfo {name} >/dev/null 2>&1",
              f"virsh dumpxml {name} | grep -q '<name>{name}</name>'",
              f"virsh pool-info {pool} | grep -q 'State:[[:space:]]*running'",
              f"virsh pool-info {pool} | grep -q 'Autostart:[[:space:]]*yes'",
          ],
          [
              f"virsh define {xml}",
              f"virsh pool-define-as --name {pool} --type dir --target /var/lib/libvirt/{pool}",
              f"virsh pool-start {pool}",
              f"virsh pool-autostart {pool}",
          ])


def cloud_q(qid: str, n: int, name: str) -> None:
    qcow = f"/var/lib/libvirt/images/{name}.qcow2"
    meta = f"/var/lib/libvirt/images/{name}-meta.yaml"
    write(qid, f"Prepare cloud image disk {name}", "cloud-image VMs", "ubuntu",
          f"""Prepare cloud-image artifacts without booting a nested VM.
Create a qcow2 overlay disk at {qcow} sized {n}G and write metadata file {meta} with instance-id {name}.""",
          ["Use qemu-img create.", "No nested guest should be started."],
          [f"rm -f {qcow} {meta}", "mkdir -p /var/lib/libvirt/images"],
          [
              f"test -f {qcow}",
              f"qemu-img info {qcow} | grep -q 'file format: qcow2'",
              f"qemu-img info {qcow} | grep -q 'virtual size: {n} GiB'",
              f"grep -q '^instance-id: {name}$' {meta}",
          ],
          [
              f"qemu-img create -f qcow2 {qcow} {n}G",
              f"cat > {meta} <<'EOF'\ninstance-id: {name}\nlocal-hostname: {name}\nEOF",
          ])


def ssl_q(qid: str, n: int, name: str) -> None:
    key = f"/etc/ssl/private/{name}.key"
    crt = f"/etc/ssl/certs/{name}.crt"
    write(qid, f"Create TLS certificate {name}", "SSL/TLS openssl", "ubuntu",
          f"""Create a 2048-bit RSA private key {key} and a self-signed certificate {crt}.
The certificate subject common name must be {name}.lfcs.local and the key/certificate pair must match.""",
          ["Use openssl req -x509.", "Compare public moduli or public keys."],
          [f"rm -f {key} {crt}"],
          [
              f"test -f {key} -a -f {crt}",
              f"test \"$(stat -c %a {key})\" = \"600\"",
              f"openssl x509 -in {crt} -noout -subject | grep -q 'CN = {name}.lfcs.local\\|CN={name}.lfcs.local'",
              f"diff -q <(openssl rsa -in {key} -pubout 2>/dev/null) <(openssl x509 -in {crt} -pubkey -noout 2>/dev/null) >/dev/null",
          ],
          [
              f"openssl req -x509 -nodes -newkey rsa:2048 -days {30+n} -keyout {key} -out {crt} -subj '/CN={name}.lfcs.local'",
              f"chmod 0600 {key}",
          ])


def local_sec(qid: str, n: int, name: str) -> None:
    conf = f"/etc/profile.d/{name}.sh"
    write(qid, f"Set local security defaults {name}", "local security", "ubuntu",
          f"""Configure a system-wide shell default in {conf}.
Interactive shells must receive umask 027 and TMOUT={600+n}; the file must not be world-writable.""",
          ["Use /etc/profile.d for shell defaults.", "Validate permissions as well as content."],
          [f"rm -f {conf}"],
          [
              f"test -f {conf}",
              f"grep -q '^umask 027$' {conf}",
              f"grep -q '^TMOUT={600+n}$' {conf}",
              f"test \"$(stat -c %a {conf})\" = \"644\"",
          ],
          [
              f"cat > {conf} <<'EOF'\numask 027\nTMOUT={600+n}\nreadonly TMOUT\nexport TMOUT\nEOF",
              f"chmod 0644 {conf}",
          ])


def rocky_repo(qid: str, n: int, name: str) -> None:
    repo = f"/etc/yum.repos.d/{name}.repo"
    write(qid, f"Use offline dnf repository {name}", "dnf/yum repositories", "rocky",
          f"""Configure the offline repository at /opt/lfcs-r04-repo in {repo}.
Install lfcs-r04-tool from that local repository without using a network mirror.""",
          ["Use baseurl=file:///opt/lfcs-r04-repo.", "Disable gpgcheck for the local lab package."],
          [
              "dnf remove -y lfcs-r04-tool >/dev/null 2>&1 || true",
              "mkdir -p /etc/yum.repos.d",
              f"rm -f {repo}",
              "dnf clean all >/dev/null 2>&1 || true",
          ],
          [
              f"test -f {repo}",
              f"grep -q 'baseurl=file:///opt/lfcs-r04-repo' {repo}",
              "rpm -q lfcs-r04-tool >/dev/null 2>&1",
          ],
          [
              "mkdir -p /etc/yum.repos.d",
              f"cat > {repo} <<'EOF'\n[{name}]\nname={name}\nbaseurl=file:///opt/lfcs-r04-repo\nenabled=1\ngpgcheck=0\nmetadata_expire=1h\nEOF",
              f"dnf --disablerepo='*' --enablerepo='{name}' install -y lfcs-r04-tool",
          ])


def selinux_bool(qid: str, boolean: str, name: str) -> None:
    write(qid, f"Persist SELinux boolean {boolean}", "SELinux enable/manage", "rocky",
          f"""Ensure SELinux is enforcing and persistently enable the boolean {boolean}.
The change must survive a policy reload.""",
          ["Use setsebool -P.", "getenforce must report Enforcing."],
          [f"setsebool -P {boolean} off >/dev/null 2>&1 || true", "setenforce 1 || true"],
          [
              "test \"$(getenforce)\" = \"Enforcing\"",
              f"getsebool {boolean} | grep -q -- '--> on'",
          ],
          ["setenforce 1", f"setsebool -P {boolean} on"])


def selinux_ctx(qid: str, n: int, name: str) -> None:
    path = f"/var/www/{name}"
    write(qid, f"Persist SELinux context for {name}", "SELinux context mgmt", "rocky",
          f"""The directory {path} and its files have the wrong SELinux type.
Add a persistent fcontext rule so everything below {path} is httpd_sys_content_t, then restore the context.""",
          ["Use semanage fcontext -a.", "restorecon applies persistent file-context rules."],
          [
              f"mkdir -p {path}",
              f"echo LFCS-{n} > {path}/index.html",
              f"chcon -R system_u:object_r:default_t:s0 {path}",
              f"semanage fcontext -d '{path}(/.*)?' >/dev/null 2>&1 || true",
          ],
          [
              f"ls -Zd {path} | grep -q 'httpd_sys_content_t'",
              f"ls -Z {path}/index.html | grep -q 'httpd_sys_content_t'",
          ],
          [
              f"semanage fcontext -a -t httpd_sys_content_t '{path}(/.*)?'",
              f"restorecon -Rv {path}",
          ])


def coverage() -> None:
    src_rows = []
    for line in (ROOT / "docs" / "QUESTION_SOURCE.md").read_text(encoding="utf-8").splitlines():
        if not line.startswith("| ") or "---" in line or "domain" in line:
            continue
        parts = [p.strip() for p in line.strip("|").split("|")]
        if len(parts) == 5:
            src_rows.append({"domain": parts[0], "topic": parts[1], "target": int(parts[2]), "distro": parts[3], "multivm": parts[4]})
    counts: dict[tuple[str, str], int] = {}
    for q in (ROOT / "questions").glob("*.yaml"):
        text = q.read_text(encoding="utf-8")
        dom = re.search(r'^domain:\s*"?([^"\n]+)"?', text, re.M)
        top = re.search(r'^topic:\s*"?([^"\n]+)"?', text, re.M)
        if dom and top:
            counts[(dom.group(1).strip(), top.group(1).strip())] = counts.get((dom.group(1).strip(), top.group(1).strip()), 0) + 1
    lines = ["# LFCS Bank Coverage", "", "Generated from `docs/QUESTION_SOURCE.md` and `questions/*.yaml`.", "", "| domain | topic | target_count | built_count | remaining | distro | multivm |", "|---|---|---:|---:|---:|---|---|"]
    for r in src_rows:
        built = counts.get((r["domain"], r["topic"]), 0)
        lines.append(f'| {r["domain"]} | {r["topic"]} | {r["target"]} | {built} | {max(r["target"] - built, 0)} | {r["distro"]} | {r["multivm"]} |')
    (ROOT / "docs" / "BANK_COVERAGE.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    # Ubuntu q059-q104
    for i, qid in enumerate(["q059", "q060", "q061", "q062"], 1):
        systemd(qid, i, f"lfcs-op-svc{i}")
    for i, qid in enumerate(["q063", "q064", "q065", "q066"], 5):
        process(qid, i, f"lfcs-op-proc{i}")
    for i, qid in enumerate(["q067", "q068", "q069", "q070"], 1):
        logging(qid, i, f"lfcs-op-log{i}")
    for i, qid in zip([5, 10, 15], ["q071", "q072", "q073"]):
        cron(qid, i, f"lfcs-op-cron{i}")
    for i, qid in enumerate(["q074", "q075", "q076"], 1):
        apt_repo(qid, i, f"lfcs-op-apt{i}")
    for i, qid in enumerate(["q077", "q078", "q079"], 1):
        compile_src(qid, i, f"lfcs-hello-op{i}")
    for i, qid in zip([6, 8, 10, 12], ["q080", "q081", "q082", "q083"]):
        resource(qid, i, f"lfcs-op-mon{i}")
    for qid, key, value, name in [
        ("q084", "net.ipv4.ip_forward", "1", "lfcs-op-sysctl1"),
        ("q085", "net.ipv4.conf.all.rp_filter", "0", "lfcs-op-sysctl2"),
        ("q086", "kernel.dmesg_restrict", "1", "lfcs-op-sysctl3"),
    ]:
        sysctl_q(qid, key, value, name)
    for i, qid in enumerate(["q087", "q088", "q089"], 1):
        apparmor(qid, i, f"lfcs-op-aa{i}")
    for i, qid in enumerate(["q090", "q091", "q092", "q093"], 1):
        docker_q(qid, i, f"lfcs-op-docker{i}")
    for i, qid in enumerate(["q094", "q095", "q096"], 1):
        virsh_q(qid, i, f"lfcs-op-vm{i}")
    for i, qid in zip([1, 2, 3], ["q097", "q098", "q099"]):
        cloud_q(qid, i, f"lfcs-op-cloud{i}")
    for i, qid in enumerate(["q100", "q101", "q102"], 1):
        ssl_q(qid, i, f"lfcs-op-tls{i}")
    for i, qid in enumerate(["q103", "q104"], 1):
        local_sec(qid, i, f"lfcs-op-sec{i}")

    # Rocky qR05-qR12
    rocky_repo("qR05", 5, "lfcs-r05-local")
    rocky_repo("qR06", 6, "lfcs-r06-local")
    selinux_bool("qR07", "httpd_can_sendmail", "lfcs-r07")
    selinux_bool("qR08", "nis_enabled", "lfcs-r08")
    selinux_bool("qR09", "virt_use_nfs", "lfcs-r09")
    selinux_ctx("qR10", 10, "lfcs-r10-site")
    selinux_ctx("qR11", 11, "lfcs-r11-site")
    selinux_ctx("qR12", 12, "lfcs-r12-site")
    coverage()


if __name__ == "__main__":
    main()
