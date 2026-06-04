from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
N1 = "192.168.56.11"
N2 = "192.168.56.12"


def script(lines: list[str]) -> str:
    return "#!/usr/bin/env bash\nset -euo pipefail\n" + "\n".join(lines) + "\n"


def validate(lines: list[str]) -> str:
    return "#!/usr/bin/env bash\nset -euo pipefail\nfail(){ echo \"RESULT: FAIL - $1\"; exit 1; }\n" + "\n".join(lines) + "\necho \"RESULT: PASS\"\n"


def write_yaml(qid: str, title: str, domain: str, topic: str, question: str, hints: list[str]) -> None:
    body = "\n".join([
        f"id: {qid}",
        f'title: "{title}"',
        f'domain: "{domain}"',
        f'topic: "{topic}"',
        "difficulty: hard",
        "distro: ubuntu",
        "vms: [node1,node2]",
        "question: |",
        *[f"  {line}" for line in question.strip().splitlines()],
        "hints: " + json.dumps(hints),
        "",
    ])
    (ROOT / "questions" / f"{qid}.yaml").write_text(body, encoding="utf-8", newline="\n")


def write_pair(qid: str, title: str, domain: str, topic: str, question: str, hints: list[str],
               inject1: list[str], inject2: list[str], solution1: list[str], solution2: list[str],
               checks: list[str]) -> None:
    write_yaml(qid, title, domain, topic, question, hints)
    (ROOT / "inject" / f"{qid}.node1.sh").write_text(script(inject1), encoding="utf-8", newline="\n")
    (ROOT / "inject" / f"{qid}.node2.sh").write_text(script(inject2), encoding="utf-8", newline="\n")
    (ROOT / "solution" / f"{qid}.node1.sh").write_text(script(solution1), encoding="utf-8", newline="\n")
    (ROOT / "solution" / f"{qid}.node2.sh").write_text(script(solution2), encoding="utf-8", newline="\n")
    (ROOT / "validate" / f"{qid}.sh").write_text(validate(checks), encoding="utf-8", newline="\n")


def nfs(qid: str, n: int) -> None:
    export = f"/srv/lfcs-nfs{n}"
    mount = f"/mnt/lfcs-nfs{n}"
    text = f"NFS-{n}-OK"
    write_pair(qid, f"Mount NFS export {n}", "Storage", "NFS",
               f"On node2, export {export} to node1 ({N1}) as read-only NFS. On node1, mount it at {mount} persistently using node2's host-only IP {N2}. The file {export}/data.txt must be readable from node1 and contain {text}.",
               ["Configure /etc/exports on node2.", "Mount from node1 using the host-only address."],
               [f"umount {mount} >/dev/null 2>&1 || true", f"rm -rf {mount}", f"sed -i '\\#{mount}#d' /etc/fstab"],
               [f"exportfs -u {N1}:{export} >/dev/null 2>&1 || true", f"sed -i '\\#{export}#d' /etc/exports", f"rm -rf {export}", "exportfs -ra || true"],
               [f"mkdir -p {mount}", f"grep -q '^{N2}:{export}[[:space:]]\\+{mount}[[:space:]]\\+nfs' /etc/fstab || echo '{N2}:{export} {mount} nfs ro,_netdev 0 0' >> /etc/fstab", "mount -a"],
               [f"mkdir -p {export}", f"echo '{text}' > {export}/data.txt", f"grep -q '^{export}[[:space:]]' /etc/exports || echo '{export} {N1}(ro,sync,no_subtree_check)' >> /etc/exports", "systemctl enable --now nfs-server || systemctl enable --now nfs-kernel-server", "exportfs -ra"],
               [f"[ \"$(findmnt -rn -o TARGET {mount} 2>/dev/null)\" = '{mount}' ] || fail 'NFS mountpoint is not mounted'",
                f"findmnt -rn -o FSTYPE {mount} 2>/dev/null | grep -Eq '^nfs' || fail 'mount is not NFS'",
                f"[ \"$(findmnt -rn -o SOURCE {mount} 2>/dev/null)\" = '{N2}:{export}' ] || fail 'wrong NFS source'",
                f"grep -Fxq '{text}' {mount}/data.txt || fail 'exported data is not readable from node1'",
                f"awk '$1==\"{N2}:{export}\" && $2==\"{mount}\" && $3==\"nfs\" {{found=1}} END {{exit !found}}' /etc/fstab || fail 'persistent NFS fstab entry missing'",
                f"showmount -e {N2} | awk '$1==\"{export}\" && $0 ~ /{N1}/ {{found=1}} END {{exit !found}}' || fail 'node2 export is not visible to node1'"])


def nbd(qid: str, n: int) -> None:
    name = f"lfcsnbd{n}"
    img = f"/srv/{name}.img"
    dev = f"/dev/nbd{n-1}"
    mount = f"/mnt/{name}"
    write_pair(qid, f"Connect NBD export {name}", "Storage", "NBD",
               f"On node2, export a 64M NBD image named {name} from {img}. On node1, connect it as {dev}, create an ext4 filesystem labeled {name}, and mount it at {mount}.",
               ["Use nbd-server on node2.", "Use nbd-client from node1."],
               [f"umount {mount} >/dev/null 2>&1 || true", f"nbd-client -d {dev} >/dev/null 2>&1 || true", f"rm -rf {mount}"],
               [f"sed -i '/\\[{name}\\]/,/^$/d' /etc/nbd-server/config || true", f"rm -f {img}", "systemctl restart nbd-server >/dev/null 2>&1 || true"],
               ["modprobe nbd max_part=8", f"nbd-client -d {dev} >/dev/null 2>&1 || true", "sleep 2", f"nbd-client {N2} -N {name} {dev}", f"mkfs.ext4 -F -L {name} {dev}", f"mkdir -p {mount}", f"mount {dev} {mount}"],
               [f"mkdir -p /srv", f"truncate -s 64M {img}", f"chown nbd:nbd {img}", f"chmod 660 {img}", "mkdir -p /etc/nbd-server", f"grep -q '^\\[{name}\\]' /etc/nbd-server/config || printf '\\n[{name}]\\nexportname = {img}\\n' >> /etc/nbd-server/config", "systemctl enable --now nbd-server", "systemctl restart nbd-server"],
               [f"[ \"$(findmnt -rn -o TARGET {mount} 2>/dev/null)\" = '{mount}' ] || fail 'NBD filesystem is not mounted'",
                f"[ \"$(findmnt -rn -o SOURCE {mount} 2>/dev/null)\" = '{dev}' ] || fail 'wrong NBD device mounted'",
                f"[ \"$(findmnt -rn -o FSTYPE {mount} 2>/dev/null)\" = 'ext4' ] || fail 'NBD filesystem is not ext4'",
                f"[ \"$(blkid -o value -s LABEL {dev} 2>/dev/null)\" = '{name}' ] || fail 'NBD filesystem label is wrong'",
                f"timeout 3 bash -c '</dev/tcp/{N2}/10809' || fail 'node2 NBD service is not reachable'"])


def nat(qid: str, n: int) -> None:
    port = 18600 + n
    text = f"NAT-{n}-NODE2"
    write_pair(qid, f"Forward node1 port {port} to node2", "Networking", "port redirection & NAT",
               f"On node2, run a web response on TCP {port} containing {text}. On node1, redirect TCP {port} arriving at {N1} to node2 {N2}:{port} and enable forwarding.",
               ["Use iptables nat rules.", "Validate by curling node1's host-only IP."],
               ["iptables -t nat -F LFCSNAT >/dev/null 2>&1 || true", "iptables -t nat -D OUTPUT -j LFCSNAT >/dev/null 2>&1 || true", "iptables -t nat -X LFCSNAT >/dev/null 2>&1 || true", "sysctl -w net.ipv4.ip_forward=0 >/dev/null 2>&1 || true"],
               [f"pkill -f 'lfcs-nat-{n}' >/dev/null 2>&1 || true"],
               ["sysctl -w net.ipv4.ip_forward=1", "iptables -t nat -N LFCSNAT || true", "iptables -t nat -C OUTPUT -j LFCSNAT 2>/dev/null || iptables -t nat -A OUTPUT -j LFCSNAT", f"iptables -t nat -A LFCSNAT -p tcp -d {N1} --dport {port} -j DNAT --to-destination {N2}:{port}"],
               [f"nohup python3 -c \"import http.server,socketserver; socketserver.TCPServer.allow_reuse_address=True; h=http.server.SimpleHTTPRequestHandler; open('/tmp/lfcs-nat-{n}.txt','w').write('{text}'); import os; os.chdir('/tmp'); socketserver.TCPServer(('{N2}',{port}),h).serve_forever()\" >/tmp/lfcs-nat-{n}.log 2>&1 &"],
               ["[ \"$(sysctl -n net.ipv4.ip_forward)\" = '1' ] || fail 'ip_forward is not enabled'",
                f"iptables -t nat -S LFCSNAT | grep -q -- '--dport {port} .*--to-destination {N2}:{port}' || fail 'DNAT rule missing'",
                f"curl -fsS --max-time 5 http://{N1}:{port}/lfcs-nat-{n}.txt | grep -Fxq '{text}' || fail 'node1 port does not reach node2 backend'"])


def proxy(qid: str, n: int) -> None:
    backend = 18700 + n
    listen = 18800 + n
    text = f"PROXY-{n}-NODE2"
    write_pair(qid, f"Reverse proxy to node2 backend {n}", "Networking", "reverse proxy & load balancer",
               f"On node2, serve HTTP on {N2}:{backend} returning {text}. On node1, configure nginx to listen on TCP {listen} and reverse proxy to that backend.",
               ["Use nginx proxy_pass.", "Validate with curl against node1."],
               [f"rm -f /etc/nginx/sites-enabled/lfcs-proxy{n} /etc/nginx/sites-available/lfcs-proxy{n}", "systemctl restart nginx >/dev/null 2>&1 || true"],
               [f"pkill -f 'lfcs-proxy-{n}' >/dev/null 2>&1 || true"],
               [f"cat > /etc/nginx/sites-available/lfcs-proxy{n} <<'EOF'\nserver {{ listen {listen}; location / {{ proxy_pass http://{N2}:{backend}; }} }}\nEOF", f"ln -sf /etc/nginx/sites-available/lfcs-proxy{n} /etc/nginx/sites-enabled/lfcs-proxy{n}", "nginx -t", "systemctl enable --now nginx", "systemctl restart nginx"],
               [f"nohup python3 -c \"import http.server,socketserver; socketserver.TCPServer.allow_reuse_address=True; open('/tmp/lfcs-proxy-{n}.txt','w').write('{text}'); import os; os.chdir('/tmp'); socketserver.TCPServer(('{N2}',{backend}),http.server.SimpleHTTPRequestHandler).serve_forever()\" >/tmp/lfcs-proxy-{n}.log 2>&1 &"],
               [f"ss -ltn sport = :{listen} | grep -q ':{listen}' || fail 'nginx is not listening on requested port'",
                f"curl -fsS --max-time 5 http://127.0.0.1:{listen}/lfcs-proxy-{n}.txt | grep -Fxq '{text}' || fail 'proxy does not return node2 backend response'",
                f"nginx -T 2>/dev/null | grep -q 'proxy_pass http://{N2}:{backend}' || fail 'nginx proxy_pass target is wrong'"])


def ntp(qid: str, n: int) -> None:
    write_pair(qid, f"Sync chrony from node2 {n}", "Networking", "NTP time sync",
               f"Configure node2 as a chrony NTP server for node1 on the host-only network. Configure node1 to use only {N2} as its chrony source.",
               ["Use chrony allow on node2.", "Use server 192.168.56.12 iburst on node1."],
               ["sed -i '/192.168.56.12/d;/lfcs-ntp/d' /etc/chrony/chrony.conf", "systemctl restart chrony || true"],
               ["sed -i '/192.168.56.11/d;/local stratum/d' /etc/chrony/chrony.conf", "systemctl restart chrony || true"],
               ["sed -i '/^pool /d;/^server /d' /etc/chrony/chrony.conf", f"echo 'server {N2} iburst' >> /etc/chrony/chrony.conf", "systemctl enable --now chrony", "systemctl restart chrony", "sleep 3", "chronyc -a makestep >/dev/null 2>&1 || true"],
               [f"grep -q '^allow {N1}' /etc/chrony/chrony.conf || echo 'allow {N1}' >> /etc/chrony/chrony.conf", "grep -q '^local stratum 10' /etc/chrony/chrony.conf || echo 'local stratum 10' >> /etc/chrony/chrony.conf", "systemctl enable --now chrony", "systemctl restart chrony"],
               [f"grep -Eq '^server[[:space:]]+{N2}[[:space:]]+iburst' /etc/chrony/chrony.conf || fail 'node1 chrony source is wrong'",
                "systemctl is-active --quiet chrony || fail 'chrony is not active on node1'",
                f"chronyc sources -n | grep -q '{N2}' || fail 'node2 is not listed as chrony source'",
                f"timeout 3 bash -c '</dev/udp/{N2}/123' || true"])


def sshx(qid: str, n: int) -> None:
    user = f"remoteuser{n}"
    alias = f"lfcs-node2-{n}"
    write_pair(qid, f"Configure key SSH node1 to node2 {n}", "Networking", "SSH server & client",
               f"Create user {user} on node2. From node1, configure key-based SSH to node2 using alias {alias}, strict known_hosts, and the host-only IP {N2}. Non-interactive ssh {alias} true must succeed without a password.",
               ["Install node1's public key in node2 authorized_keys.", "Use /root/.ssh/config and ssh-keyscan."],
               [f"rm -f /vagrant/.tmp-{qid}.pub", f"rm -rf /root/.ssh/lfcs-{qid} /root/.ssh/config", f"ssh-keygen -R {N2} >/dev/null 2>&1 || true", f"ssh-keygen -R {alias} >/dev/null 2>&1 || true"],
               [f"userdel -r {user} >/dev/null 2>&1 || true", f"rm -f /vagrant/.tmp-{qid}.pub"],
               ["install -d -m 700 /root/.ssh", f"ssh-keygen -q -t ed25519 -N '' -f /root/.ssh/lfcs-{qid}", f"cp /root/.ssh/lfcs-{qid}.pub /vagrant/.tmp-{qid}.pub", f"ssh-keyscan -H {N2} >> /root/.ssh/known_hosts 2>/dev/null", f"cat > /root/.ssh/config <<'EOF'\nHost {alias}\n  HostName {N2}\n  User {user}\n  IdentityFile /root/.ssh/lfcs-{qid}\n  IdentitiesOnly yes\n  StrictHostKeyChecking yes\nEOF", "chmod 600 /root/.ssh/config"],
               [f"useradd -m -s /bin/bash {user}", f"install -d -m 700 -o {user} -g {user} /home/{user}/.ssh", f"cat /vagrant/.tmp-{qid}.pub > /home/{user}/.ssh/authorized_keys", f"chown -R {user}:{user} /home/{user}/.ssh", f"chmod 600 /home/{user}/.ssh/authorized_keys", "systemctl enable --now ssh", "systemctl restart ssh"],
               [f"test -s /root/.ssh/lfcs-{qid} || fail 'node1 private key missing'",
                f"grep -q '^Host {alias}$' /root/.ssh/config || fail 'ssh alias missing'",
                f"grep -q 'HostName {N2}' /root/.ssh/config || fail 'ssh HostName is wrong'",
                f"ssh-keygen -F {N2} >/dev/null || fail 'known_hosts entry missing'",
                f"ssh -F /root/.ssh/config -o BatchMode=yes {alias} true || fail 'non-interactive SSH to node2 failed'"])


def ldap(qid: str, n: int) -> None:
    user = f"ldapuser{n}"
    uid = 3100 + n
    write_pair(qid, f"Resolve LDAP account {user}", "Users and Groups", "LDAP accounts",
               f"Configure node2 LDAP directory dc=lfcs,dc=lab with POSIX user {user} UID {uid}. Configure node1 NSS over LDAP so getent passwd {user} returns that LDAP account.",
               ["Node2 is the LDAP server.", "Node1 is the LDAP client."],
               ["sed -i 's/^passwd:.*/passwd:         files systemd/' /etc/nsswitch.conf", "systemctl restart nslcd >/dev/null 2>&1 || true"],
               [f"ldapdelete -x -D cn=admin,dc=lfcs,dc=lab -w admin uid={user},ou=People,dc=lfcs,dc=lab >/dev/null 2>&1 || true", "ldapdelete -x -D cn=admin,dc=lfcs,dc=lab -w admin ou=People,dc=lfcs,dc=lab >/dev/null 2>&1 || true"],
               [f"cat > /etc/nslcd.conf <<'EOF'\nuid nslcd\ngid nslcd\nuri ldap://{N2}/\nbase dc=lfcs,dc=lab\nEOF", "sed -i 's/^passwd:.*/passwd:         files systemd ldap/' /etc/nsswitch.conf", "sed -i 's/^group:.*/group:          files systemd ldap/' /etc/nsswitch.conf", "systemctl enable --now nslcd", "systemctl restart nslcd"],
               ["systemctl enable --now slapd", "ldapadd -x -D cn=admin,dc=lfcs,dc=lab -w admin <<'EOF' >/dev/null 2>&1 || true\ndn: ou=People,dc=lfcs,dc=lab\nobjectClass: organizationalUnit\nou: People\nEOF", f"ldapadd -x -D cn=admin,dc=lfcs,dc=lab -w admin <<'EOF'\ndn: uid={user},ou=People,dc=lfcs,dc=lab\nobjectClass: inetOrgPerson\nobjectClass: posixAccount\nobjectClass: shadowAccount\ncn: {user}\nsn: {user}\nuid: {user}\nuidNumber: {uid}\ngidNumber: {uid}\nhomeDirectory: /home/{user}\nloginShell: /bin/bash\nuserPassword: password\nEOF"],
               [f"getent passwd {user} | awk -F: '$1==\"{user}\" && $3=={uid} && $6==\"/home/{user}\" && $7==\"/bin/bash\" {{found=1}} END {{exit !found}}' || fail 'LDAP passwd entry not visible on node1'",
                f"ldapsearch -x -H ldap://{N2}/ -b dc=lfcs,dc=lab uid={user} uidNumber | grep -q 'uidNumber: {uid}' || fail 'LDAP server entry is missing or wrong'",
                f"grep -Eq '^uri[[:space:]]+ldap://{N2}/' /etc/nslcd.conf || fail 'node1 LDAP URI is wrong'",
                "grep -Eq '^passwd:.*ldap' /etc/nsswitch.conf || fail 'node1 passwd NSS does not include ldap'"])


def update_coverage() -> None:
    rows = []
    for line in (ROOT / "docs" / "QUESTION_SOURCE.md").read_text(encoding="utf-8").splitlines():
        if not line.startswith("| ") or "---" in line or "domain" in line:
            continue
        parts = [p.strip() for p in line.strip("|").split("|")]
        if len(parts) == 5:
            rows.append((parts[0], parts[1], int(parts[2]), parts[3], parts[4]))
    counts: dict[tuple[str, str], int] = {}
    for q in (ROOT / "questions").glob("*.yaml"):
        text = q.read_text(encoding="utf-8")
        dom = re.search(r'^domain:\s*"?([^"\n]+)"?', text, re.M)
        top = re.search(r'^topic:\s*"?([^"\n]+)"?', text, re.M)
        if dom and top:
            key = (dom.group(1).strip(), top.group(1).strip())
            counts[key] = counts.get(key, 0) + 1
    total_built = sum(counts.values())
    out = ["# LFCS Bank Coverage", "", "Generated from `docs/QUESTION_SOURCE.md` and `questions/*.yaml`.", "", f"Total built questions: {total_built}", "", "| domain | topic | target_count | built_count | remaining | distro | multivm |", "|---|---|---:|---:|---:|---|---|"]
    for domain, topic, target, distro, multivm in rows:
        built = counts.get((domain, topic), 0)
        out.append(f"| {domain} | {topic} | {target} | {built} | {max(target-built, 0)} | {distro} | {multivm} |")
    (ROOT / "docs" / "BANK_COVERAGE.md").write_text("\n".join(out) + "\n", encoding="utf-8")


def main() -> None:
    q = 199
    for n in range(1, 7):
        nfs(f"q{q:03d}", n); q += 1
    for n in range(1, 5):
        nbd(f"q{q:03d}", n); q += 1
    for n in range(1, 7):
        nat(f"q{q:03d}", n); q += 1
    for n in range(1, 6):
        proxy(f"q{q:03d}", n); q += 1
    for n in range(1, 6):
        ntp(f"q{q:03d}", n); q += 1
    for n in range(1, 6):
        sshx(f"q{q:03d}", n); q += 1
    for n in range(1, 5):
        ldap(f"q{q:03d}", n); q += 1
    update_coverage()


if __name__ == "__main__":
    main()
