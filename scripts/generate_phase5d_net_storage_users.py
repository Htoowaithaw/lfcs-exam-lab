from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def script(lines: list[str]) -> str:
    return "#!/usr/bin/env bash\nset -euo pipefail\n" + "\n".join(lines) + "\n"


def validate_script(checks: list[tuple[str, str]]) -> str:
    lines = []
    for command, reason in checks:
        safe = reason.replace('"', "'").replace("$", "\\$")
        lines.append(f'if ! {command}; then echo "RESULT: FAIL - {safe}"; exit 1; fi')
    lines.append('echo "RESULT: PASS"')
    return script(lines)


def write(qid: str, title: str, domain: str, topic: str, distro: str, question: str,
          hints: list[str], inject: list[str], checks: list[tuple[str, str]], solution: list[str],
          difficulty: str = "medium") -> None:
    vm = "lfcs-rocky1" if distro == "rocky" else "node1"
    yaml = "\n".join([
        f"id: {qid}",
        f'title: "{title}"',
        f'domain: "{domain}"',
        f'topic: "{topic}"',
        f"difficulty: {difficulty}",
        f"distro: {distro}",
        f"vms: [{vm}]",
        "question: |",
        *[f"  {line}" for line in question.strip().splitlines()],
        "hints: " + json.dumps(hints),
        "",
    ])
    (ROOT / "questions" / f"{qid}.yaml").write_text(yaml, encoding="utf-8", newline="\n")
    (ROOT / "inject" / f"{qid}.sh").write_text(script(inject), encoding="utf-8", newline="\n")
    (ROOT / "validate" / f"{qid}.sh").write_text(validate_script(checks), encoding="utf-8", newline="\n")
    (ROOT / "solution" / f"{qid}.sh").write_text(script(solution), encoding="utf-8", newline="\n")


def shquote(s: str) -> str:
    return "'" + s.replace("'", "'\"'\"'") + "'"


def net_addr(qid: str, n: int) -> None:
    iface = f"lfcsnet{n}"
    ip4 = f"10.55.{n}.10/24"
    ip6 = f"fd00:55:{n}::10/64"
    host = f"phase5d-net{n}.local"
    write(qid, f"Configure local address and host entry {iface}", "Networking", "IPv4/IPv6 + hostname resolution", "ubuntu",
          f"""Create a dummy interface named {iface}, bring it up, assign IPv4 {ip4} and IPv6 {ip6}, and add /etc/hosts entry mapping 10.55.{n}.10 to {host}.""",
          ["Use ip link add type dummy.", "Validate both ip addr and getent hosts."],
          [f"ip link delete {iface} >/dev/null 2>&1 || true", f"sed -i '/{host}/d' /etc/hosts"],
          [(f"ip -4 addr show dev {iface} | grep -q '10.55.{n}.10/24'", "missing IPv4 address"),
           (f"ip -6 addr show dev {iface} | grep -q 'fd00:55:{n}::10/64'", "missing IPv6 address"),
           (f"getent hosts {host} | grep -q '10.55.{n}.10'", "missing hosts entry")],
          [f"ip link add {iface} type dummy", f"ip addr add {ip4} dev {iface}", f"ip -6 addr add {ip6} dev {iface}", f"ip link set {iface} up",
           f"echo '10.55.{n}.10 {host}' >> /etc/hosts"])


def host_only(qid: str, n: int) -> None:
    host = f"lfcs-host{n}.example"
    write(qid, f"Add hostname resolution for {host}", "Networking", "IPv4/IPv6 + hostname resolution", "ubuntu",
          f"Add a local resolver entry so {host} resolves to 192.0.2.{n}.",
          ["Use /etc/hosts.", "getent hosts should show the requested address."],
          [f"sed -i '/{host}/d' /etc/hosts"],
          [(f"getent hosts {host} | grep -q '192.0.2.{n}'", "host does not resolve to requested address")],
          [f"echo '192.0.2.{n} {host}' >> /etc/hosts"])


def ss_service(qid: str, n: int) -> None:
    port = 18100 + n
    pid = f"/run/lfcs-ss{n}.pid"
    write(qid, f"Start a checked listener on port {port}", "Networking", "ss/netstat service checks", "ubuntu",
          f"Start a local TCP listener bound to 127.0.0.1:{port}, keep it running, and write its PID to {pid}.",
          ["A tiny Python socket server is enough.", "Validate with ss -ltn."],
          [f"if test -f {pid}; then kill $(cat {pid}) >/dev/null 2>&1 || true; fi", f"rm -f {pid}"],
          [(f"test -s {pid}", "PID file missing"),
           (f"kill -0 $(cat {pid})", "listener PID is not running"),
           (f"ss -ltn sport = :{port} | grep -q '127.0.0.1:{port}'", "port is not listening on loopback")],
          [f"nohup python3 -c \"import socket,time; s=socket.socket(); s.setsockopt(socket.SOL_SOCKET,socket.SO_REUSEADDR,1); s.bind(('127.0.0.1',{port})); s.listen(1); time.sleep(3600)\" >/tmp/lfcs-ss{n}.log 2>&1 &",
           f"echo $! > {pid}"])


def bridge(qid: str, n: int) -> None:
    br = f"brlfcs{n}"
    d1 = f"brd{n}a"
    d2 = f"brd{n}b"
    write(qid, f"Create bridge {br}", "Networking", "bridge & bonding", "ubuntu",
          f"Create Linux bridge {br}, attach dummy interfaces {d1} and {d2}, and bring all three links up.",
          ["Use ip link add type bridge and type dummy.", "ip -d link shows bridge membership."],
          [f"ip link delete {br} >/dev/null 2>&1 || true", f"ip link delete {d1} >/dev/null 2>&1 || true", f"ip link delete {d2} >/dev/null 2>&1 || true"],
          [(f"ip link show {br} | grep -q 'state UP'", "bridge is not up"),
           (f"bridge link | grep -q '{d1}'", "first bridge member missing"),
           (f"bridge link | grep -q '{d2}'", "second bridge member missing")],
          [f"ip link add {br} type bridge", f"ip link add {d1} type dummy", f"ip link add {d2} type dummy",
           f"ip link set {d1} master {br}", f"ip link set {d2} master {br}", f"ip link set {d1} up", f"ip link set {d2} up", f"ip link set {br} up"])


def bond(qid: str, n: int) -> None:
    bond = f"bondlfcs{n}"
    d1 = f"bnd{n}a"
    d2 = f"bnd{n}b"
    write(qid, f"Create active-backup bond {bond}", "Networking", "bridge & bonding", "ubuntu",
          f"Create bond {bond} in active-backup mode with dummy slaves {d1} and {d2}, then bring it up.",
          ["Load the bonding module if needed.", "Validate through /proc/net/bonding."],
          [f"ip link delete {bond} >/dev/null 2>&1 || true", f"ip link delete {d1} >/dev/null 2>&1 || true", f"ip link delete {d2} >/dev/null 2>&1 || true"],
          [(f"test -f /proc/net/bonding/{bond}", "bond details missing"),
           (f"grep -q 'Bonding Mode: fault-tolerance' /proc/net/bonding/{bond}", "bond is not active-backup"),
           (f"grep -q 'Slave Interface: {d1}' /proc/net/bonding/{bond}", "first bond slave missing"),
           (f"grep -q 'Slave Interface: {d2}' /proc/net/bonding/{bond}", "second bond slave missing")],
          ["modprobe bonding", f"ip link add {bond} type bond mode active-backup", f"ip link add {d1} type dummy", f"ip link add {d2} type dummy",
           f"ip link set {d1} master {bond}", f"ip link set {d2} master {bond}", f"ip link set {d1} up", f"ip link set {d2} up", f"ip link set {bond} up"])


def ufw_q(qid: str, n: int) -> None:
    port = 18200 + n
    write(qid, f"Open UFW port {port}", "Networking", "firewall - ufw/nftables", "ubuntu",
          f"Enable UFW with default allow policy and allow inbound TCP port {port}.",
          ["Use ufw --force enable.", "Do not lock yourself out; keep default allow for this lab."],
          ["ufw --force reset >/dev/null 2>&1 || true", "ufw default allow incoming >/dev/null", "ufw default allow outgoing >/dev/null"],
          [("ufw status | grep -q 'Status: active'", "ufw is not active"),
           (f"ufw status | grep -q '{port}/tcp.*ALLOW'", "requested UFW port is not allowed")],
          ["ufw default allow incoming", "ufw default allow outgoing", f"ufw allow {port}/tcp", "ufw --force enable"])


def nft_q(qid: str, n: int) -> None:
    table = f"lfcs{n}"
    port = 18300 + n
    write(qid, f"Create nftables rule for port {port}", "Networking", "firewall - ufw/nftables", "ubuntu",
          f"Create nftables table inet {table} with an input chain that accepts tcp dport {port}.",
          ["Use nft add table/chain/rule.", "Validation reads the active ruleset."],
          [f"nft delete table inet {table} >/dev/null 2>&1 || true"],
          [(f"nft list table inet {table} >/dev/null 2>&1", "nft table missing"),
           (f"nft list table inet {table} | grep -q 'tcp dport {port} accept'", "nft accept rule missing")],
          [f"nft add table inet {table}", f"nft add chain inet {table} input '{{ type filter hook input priority 0; policy accept; }}'", f"nft add rule inet {table} input tcp dport {port} accept"])


def route_q(qid: str, n: int) -> None:
    dest = f"198.51.{n}.0/24"
    write(qid, f"Add static route {dest}", "Networking", "routing", "ubuntu",
          f"Add an active static route for {dest} via the loopback device with metric {n}.",
          ["Use ip route add.", "Validation checks the live route table."],
          [f"ip route delete {dest} >/dev/null 2>&1 || true"],
          [(f"ip route show {dest} | grep -q 'dev lo'", "route does not use loopback"),
           (f"ip route show {dest} | grep -q 'metric {n}'", "route metric is wrong")],
          [f"ip route add {dest} dev lo metric {n}"])


def ssh_q(qid: str, n: int) -> None:
    user = f"sshuser{n}"
    conf = f"/etc/ssh/sshd_config.d/{qid}.conf"
    write(qid, f"Harden local SSH setting {qid}", "Networking", "SSH server & client", "ubuntu",
          f"Create user {user}, install an authorized key, and enforce key-only SSH by setting PasswordAuthentication no and PubkeyAuthentication yes in {conf}. Restart sshd.",
          ["Use ssh-keygen for a local keypair.", "Validate effective sshd config with sshd -T."],
          [f"userdel -r {user} >/dev/null 2>&1 || true", f"rm -f {conf}", "systemctl restart ssh || systemctl restart sshd"],
          [(f"getent passwd {user} >/dev/null", "ssh test user missing"),
           (f"test -s /home/{user}/.ssh/authorized_keys", "authorized_keys missing"),
           ("sshd -T | awk '$1 == \"passwordauthentication\" && $2 == \"no\" { found=1 } END { exit !found }'", "password auth is not disabled effectively"),
           ("sshd -T | awk '$1 == \"pubkeyauthentication\" && $2 == \"yes\" { found=1 } END { exit !found }'", "pubkey auth is not enabled effectively"),
           ("(systemctl is-active --quiet ssh || systemctl is-active --quiet sshd)", "ssh service is not active")],
          [f"useradd -m -s /bin/bash {user}", f"install -d -m 700 -o {user} -g {user} /home/{user}/.ssh",
           f"ssh-keygen -q -t ed25519 -N '' -f /home/{user}/.ssh/id_ed25519", f"cat /home/{user}/.ssh/id_ed25519.pub > /home/{user}/.ssh/authorized_keys",
           f"chown -R {user}:{user} /home/{user}/.ssh", f"chmod 600 /home/{user}/.ssh/authorized_keys",
           f"for f in /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf; do [ \"$f\" = \"{conf}\" ] && continue; [ -e \"$f\" ] && sed -i -E '/^[[:space:]]*PasswordAuthentication[[:space:]]+/s/^/# /' \"$f\"; done",
           f"cat > {conf} <<'EOF'\nPasswordAuthentication no\nPubkeyAuthentication yes\nEOF",
           "sshd -t", "systemctl restart ssh || systemctl restart sshd",
           "for i in {1..20}; do (systemctl is-active --quiet ssh || systemctl is-active --quiet sshd) && break; sleep 1; done"])


def firewalld_q(qid: str, n: int) -> None:
    port = 18400 + n
    write(qid, f"Open permanent firewalld port {port}", "Networking", "firewall - firewalld", "rocky",
          f"Open TCP port {port} permanently in the public firewalld zone and reload firewalld.",
          ["Use firewall-cmd --permanent.", "Validation checks the active zone after reload."],
          ["systemctl enable --now firewalld >/dev/null 2>&1 || true", f"firewall-cmd --permanent --remove-port={port}/tcp >/dev/null 2>&1 || true", "firewall-cmd --reload >/dev/null"],
          [("systemctl is-active --quiet firewalld", "firewalld is not active"),
           (f"firewall-cmd --zone=public --list-ports | grep -qw '{port}/tcp'", "port missing from active public zone"),
           (f"firewall-cmd --permanent --zone=public --list-ports | grep -qw '{port}/tcp'", "port missing from permanent public zone")],
          [f"firewall-cmd --permanent --zone=public --add-port={port}/tcp", "firewall-cmd --reload"])


def disk_clean(dev: str) -> list[str]:
    return [f"swapoff {dev}* >/dev/null 2>&1 || true",
            f"wipefs -a {dev}* >/dev/null 2>&1 || true",
            f"dd if=/dev/zero of={dev} bs=1M count=8 conv=fsync >/dev/null 2>&1 || true"]


def partition_q(qid: str, n: int) -> None:
    dev = "/dev/sdb"
    size = 64 + n * 16
    part = f"{dev}1"
    write(qid, f"Create scratch partition {size}M", "Storage", "partitioning", "ubuntu",
          f"On scratch disk {dev}, create one Linux partition {part} of size {size}M. Do not touch the OS disk.",
          ["Use sfdisk or fdisk.", "Validate with lsblk."],
          disk_clean(dev),
          [(f"test -b {part}", "scratch partition missing"),
           (f"lsblk -bno SIZE {part} | awk '{{exit !($1 >= {size}*1024*1024 && $1 < ({size}+8)*1024*1024)}}'", "partition size is wrong")],
          [f"printf 'label: dos\n, {size}M, L\n' | sfdisk {dev}", "udevadm settle || true"])


def swap_q(qid: str, n: int) -> None:
    dev = "/dev/sdc"
    part = f"{dev}1"
    write(qid, f"Create active swap on {part}", "Storage", "swap", "ubuntu",
          f"Create partition {part} on scratch disk {dev}, format it as swap, enable it, and add a persistent fstab entry by UUID.",
          ["Use mkswap and swapon.", "Do not use the OS disk."],
          disk_clean(dev) + [f"sed -i '\\#{part}#d;/lfcs-swap-{n}/d' /etc/fstab"],
          [(f"grep -q '{part}' /proc/swaps", "swap is not active"),
           (f"blkid -o value -s TYPE {part} | grep -q '^swap$'", "partition is not swap"),
           (f"grep -q 'lfcs-swap-{n}' /etc/fstab", "persistent fstab marker missing")],
          [f"printf 'label: dos\n, 128M, L\n' | sfdisk {dev}", "udevadm settle || true", f"mkswap -L lfcs-swap-{n} {part}", f"uuid=$(blkid -s UUID -o value {part})", f"echo \"UUID=$uuid none swap sw 0 0 # lfcs-swap-{n}\" >> /etc/fstab", f"swapon {part}"])


def fs_q(qid: str, n: int) -> None:
    dev = "/dev/sdd"
    part = f"{dev}1"
    label = f"lfcsfs{n}"
    write(qid, f"Create ext4 filesystem {label}", "Storage", "create/configure filesystems", "ubuntu",
          f"Create partition {part} on scratch disk {dev}, format it ext4 with label {label}, and do not mount it.",
          ["Use mkfs.ext4 -L.", "Validate with blkid."],
          disk_clean(dev),
          [(f"blkid -o value -s TYPE {part} | grep -q '^ext4$'", "filesystem type is not ext4"),
           (f"blkid -o value -s LABEL {part} | grep -q '^{label}$'", "filesystem label is wrong")],
          [f"printf 'label: dos\n, 160M, L\n' | sfdisk {dev}", "udevadm settle || true", f"mkfs.ext4 -F -L {label} {part}"])


def fstab_q(qid: str, n: int) -> None:
    dev = "/dev/sde"
    part = f"{dev}1"
    mp = f"/mnt/lfcs-fstab{n}"
    label = f"fstab{n}"
    write(qid, f"Persist mount {mp}", "Storage", "fstab boot mounts", "ubuntu",
          f"Create an ext4 filesystem labeled {label} on {part}, mount it at {mp}, add a UUID-based /etc/fstab entry, and ensure mount -a succeeds.",
          ["Use UUID rather than a raw device path.", "Validation runs mount -a."],
          disk_clean(dev) + [f"umount {mp} >/dev/null 2>&1 || true", f"rm -rf {mp}", f"sed -i '\\#{mp}#d;/lfcs-fstab-{n}/d' /etc/fstab"],
          [(f"findmnt -rn {mp} | grep -q '{mp}'", "mountpoint is not mounted"),
           (f"grep -q 'UUID=.*{mp}.*lfcs-fstab-{n}' /etc/fstab", "UUID fstab entry missing"),
           ("mount -a", "mount -a failed")],
          [f"printf 'label: dos\n, 192M, L\n' | sfdisk {dev}", "udevadm settle || true", f"mkfs.ext4 -F -L {label} {part}", f"mkdir -p {mp}", f"uuid=$(blkid -s UUID -o value {part})", f"echo \"UUID=$uuid {mp} ext4 defaults 0 2 # lfcs-fstab-{n}\" >> /etc/fstab", "mount -a"])


def mountopt_q(qid: str, n: int) -> None:
    dev = "/dev/sdf"
    part = f"{dev}1"
    mp = f"/mnt/lfcs-opt{n}"
    opt = "noexec" if n % 2 else "nosuid"
    write(qid, f"Mount filesystem with {opt}", "Storage", "mount options", "ubuntu",
          f"Create and mount ext4 filesystem {part} at {mp} with the {opt} option active and persistent.",
          ["Use fstab options.", "findmnt should show the option."],
          disk_clean(dev) + [f"umount {mp} >/dev/null 2>&1 || true", f"rm -rf {mp}", f"sed -i '\\#{mp}#d' /etc/fstab"],
          [(f"findmnt -no OPTIONS {mp} | grep -qw '{opt}'", "mount option is not active"),
           (f"grep -q '{opt}' /etc/fstab", "mount option is not persistent"),
           ("mount -a", "mount -a failed")],
          [f"printf 'label: dos\n, 128M, L\n' | sfdisk {dev}", "udevadm settle || true", f"mkfs.ext4 -F {part}", f"mkdir -p {mp}", f"uuid=$(blkid -s UUID -o value {part})", f"echo \"UUID=$uuid {mp} ext4 defaults,{opt} 0 2\" >> /etc/fstab", "mount -a"])


def lvm_q(qid: str, n: int) -> None:
    dev = "/dev/sdg"
    vg = f"vglfcs{n}"
    lv = f"lvdata{n}"
    mp = f"/mnt/lfcs-lvm{n}"
    size = 64 + n * 8
    write(qid, f"Create LVM volume {vg}/{lv}", "Storage", "LVM", "ubuntu",
          f"Use scratch disk {dev} as an LVM PV, create VG {vg}, LV {lv} sized {size}M, format ext4, and mount it at {mp}.",
          ["Use pvcreate, vgcreate, lvcreate.", "Do not touch the OS VG."],
          [f"umount {mp} >/dev/null 2>&1 || true", f"lvremove -ff /dev/{vg}/{lv} >/dev/null 2>&1 || true", f"vgremove -ff {vg} >/dev/null 2>&1 || true", f"pvremove -ff -y {dev} >/dev/null 2>&1 || true"] + disk_clean(dev) + [f"rm -rf {mp}"],
          [(f"pvs {dev} --noheadings -o pv_name | grep -q '{dev}'", "PV missing on scratch disk"),
           (f"vgs {vg} --noheadings -o vg_name | grep -q '{vg}'", "VG missing"),
           (f"lvs /dev/{vg}/{lv} --noheadings -o lv_name | grep -q '{lv}'", "LV missing"),
           (f"findmnt -rn {mp} | grep -q '/dev/mapper/{vg}-{lv}'", "LV is not mounted at requested path")],
          [f"pvcreate -ff -y {dev}", f"vgcreate {vg} {dev}", f"lvcreate -y -L {size}M -n {lv} {vg}", f"mkfs.ext4 -F /dev/{vg}/{lv}", f"mkdir -p {mp}", f"mount /dev/{vg}/{lv} {mp}"])


def perf_q(qid: str, n: int) -> None:
    out = f"/root/lfcs-storage-perf{n}.txt"
    write(qid, f"Capture storage performance facts {n}", "Storage", "storage perf monitoring", "ubuntu",
          f"Write a storage facts report to {out} containing lsblk output, df output, and blockdev read-ahead for /dev/sdb.",
          ["This is an artifact question.", "Use lsblk, df, and blockdev."],
          [f"rm -f {out}"],
          [(f"test -s {out}", "report file missing"),
           (f"grep -q '^LSBLK' {out}", "lsblk section missing"),
           (f"grep -q '^DF' {out}", "df section missing"),
           (f"grep -q '^READAHEAD' {out}", "read-ahead section missing")],
          [f"{{ echo LSBLK; lsblk; echo DF; df -h; echo READAHEAD; blockdev --getra /dev/sdb; }} > {out}"])


def raid_q(qid: str, n: int) -> None:
    d1, d2 = "/dev/sdh", "/dev/sdi"
    md = f"/dev/md/lfcsraid{n}"
    write(qid, f"Create RAID1 array lfcsraid{n}", "Storage", "RAID/mdadm", "ubuntu",
          f"Create RAID1 array {md} using scratch disks {d1} and {d2}. Format it ext4.",
          ["Use mdadm --create.", "Validation checks mdadm --detail."],
          [f"mdadm --stop {md} >/dev/null 2>&1 || true", f"rm -f {md}"] + disk_clean(d1) + disk_clean(d2),
          [(f"mdadm --detail {md} | grep -q 'Raid Level : raid1'", "RAID level is not raid1"),
           (f"mdadm --detail {md} | grep -q 'Raid Devices : 2'", "RAID device count is wrong"),
           (f"blkid -o value -s TYPE {md} | grep -q '^ext4$'", "RAID filesystem is not ext4")],
          [f"printf 'y\\n' | mdadm --create {md} --metadata=1.2 --level=1 --raid-devices=2 {d1} {d2}", "udevadm settle || true", f"mkfs.ext4 -F {md}"])


def user_local(qid: str, n: int) -> None:
    user = f"lfcsuser{n}"
    uid = 2400 + n
    write(qid, f"Create local user {user}", "Users and Groups", "local user accounts", "ubuntu",
          f"Create user {user} with UID {uid}, shell /bin/bash, and account expiry 2030-12-31.",
          ["Use useradd options.", "Validate with getent and chage."],
          [f"userdel -r {user} >/dev/null 2>&1 || true"],
          [(f"getent passwd {user} | awk -F: '{{exit !($3=={uid} && $7==\"/bin/bash\")}}'", "user UID or shell is wrong"),
           (f"chage -l {user} | grep -q 'Dec 31, 2030\\|12/31/2030'", "account expiry is wrong")],
          [f"useradd -m -u {uid} -s /bin/bash -e 2030-12-31 {user}"])


def group_q(qid: str, n: int) -> None:
    user = f"grpuser{n}"
    group = f"lfcsteam{n}"
    write(qid, f"Configure group membership {group}", "Users and Groups", "groups & memberships", "ubuntu",
          f"Create group {group}, create user {user}, and make {group} the user's supplementary group.",
          ["Use groupadd and usermod -aG.", "Validate with id."],
          [f"userdel -r {user} >/dev/null 2>&1 || true", f"groupdel {group} >/dev/null 2>&1 || true"],
          [(f"getent group {group} >/dev/null", "group missing"),
           (f"id -nG {user} | tr ' ' '\\n' | grep -qx '{group}'", "supplementary membership missing")],
          [f"groupadd {group}", f"useradd -m {user}", f"usermod -aG {group} {user}"])


def profile_q(qid: str, n: int) -> None:
    prof = f"/etc/profile.d/lfcs-profile{n}.sh"
    var = f"LFCS_PROFILE_{n}"
    write(qid, f"Set system-wide profile variable {var}", "Users and Groups", "system-wide profiles", "ubuntu",
          f"Create {prof} so login shells receive {var}=enabled{n}.",
          ["Use /etc/profile.d.", "Validate through a login shell."],
          [f"rm -f {prof}"],
          [(f"test -f {prof}", "profile script missing"),
           (f"bash -lc 'test \"${var}\" = enabled{n}'", "login shell does not receive variable")],
          [f"cat > {prof} <<'EOF'\nexport {var}=enabled{n}\nEOF", f"chmod 0644 {prof}"])


def skel_q(qid: str, n: int) -> None:
    fname = f".lfcs-skel{n}"
    user = f"skelprobe{n}"
    write(qid, f"Configure skel file {fname}", "Users and Groups", "skel template env", "ubuntu",
          f"Add /etc/skel/{fname} containing SKEL-{n}; verify newly created users receive it.",
          ["Modify /etc/skel.", "Create a probe user after the change."],
          [f"userdel -r {user} >/dev/null 2>&1 || true", f"rm -f /etc/skel/{fname}"],
          [(f"test -f /etc/skel/{fname}", "skel file missing"),
           (f"test -f /home/{user}/{fname}", "probe user did not receive skel file"),
           (f"grep -q 'SKEL-{n}' /home/{user}/{fname}", "probe skel content wrong")],
          [f"echo 'SKEL-{n}' > /etc/skel/{fname}", f"useradd -m {user}"])


def ulimit_q(qid: str, n: int) -> None:
    user = f"limituser{n}"
    conf = f"/etc/security/limits.d/lfcs-limit{n}.conf"
    nofile = 2048 + n
    write(qid, f"Set nofile limit for {user}", "Users and Groups", "ulimit resource limits", "ubuntu",
          f"Create user {user} and set both soft and hard nofile limit to {nofile} using {conf}.",
          ["Use limits.d.", "Validate with su - user -c 'ulimit -n'."],
          [f"userdel -r {user} >/dev/null 2>&1 || true", f"rm -f {conf}"],
          [(f"getent passwd {user} >/dev/null", "limit user missing"),
           (f"su - {user} -c 'ulimit -n' | grep -q '^{nofile}$'", "nofile limit not applied")],
          [f"useradd -m -s /bin/bash {user}", f"cat > {conf} <<'EOF'\n{user} soft nofile {nofile}\n{user} hard nofile {nofile}\nEOF"])


def sudo_q(qid: str, n: int) -> None:
    user = f"sudoer{n}"
    cmd = "/usr/bin/systemctl" if n % 2 else "/usr/bin/journalctl"
    file = f"/etc/sudoers.d/lfcs-sudo{n}"
    write(qid, f"Grant limited sudo to {user}", "Users and Groups", "sudo privileges", "ubuntu",
          f"Create user {user} and allow passwordless sudo for only {cmd} through {file}.",
          ["Use visudo -cf to validate sudoers syntax.", "Validate with sudo -l -U."],
          [f"userdel -r {user} >/dev/null 2>&1 || true", f"rm -f {file}"],
          [(f"getent passwd {user} >/dev/null", "sudo user missing"),
           (f"visudo -cf {file} >/dev/null", "sudoers file syntax invalid"),
           (f"sudo -l -U {user} | grep -Fq 'NOPASSWD: {cmd}'", "sudo privilege missing or too different")],
          [f"useradd -m {user}", f"cat > {file} <<'EOF'\n{user} ALL=(root) NOPASSWD: {cmd}\nEOF", f"chmod 0440 {file}", f"visudo -cf {file}"])


def root_q(qid: str, n: int) -> None:
    mode = "lock" if n % 2 else "unlock"
    inject = ["echo 'root:LFCSroot123!' | chpasswd", "passwd -u root"] if mode == "lock" else ["passwd -l root"]
    write(qid, f"Set root account {mode} state {n}", "Users and Groups", "root account access", "ubuntu",
          f"Set the root account password state to {mode}.",
          ["Use passwd -l or passwd -u.", "Validate with passwd -S root."],
          inject,
          [("passwd -S root | awk '{print $2}' | grep -q '^L$'" if mode == "lock" else "passwd -S root | awk '{print $2}' | grep -q '^P$'", f"root account is not {mode}ed")],
          (["passwd -l root"] if mode == "lock" else ["echo 'root:LFCSroot123!' | chpasswd", "passwd -u root"]))


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
    out = ["# LFCS Bank Coverage", "", "Generated from `docs/QUESTION_SOURCE.md` and `questions/*.yaml`.", "", "| domain | topic | target_count | built_count | remaining | distro | multivm |", "|---|---|---:|---:|---:|---|---|"]
    for domain, topic, target, distro, multivm in rows:
        built = counts.get((domain, topic), 0)
        out.append(f"| {domain} | {topic} | {target} | {built} | {max(target-built, 0)} | {distro} | {multivm} |")
    (ROOT / "docs" / "BANK_COVERAGE.md").write_text("\n".join(out) + "\n", encoding="utf-8")


def main() -> None:
    q = 105
    for n in range(1, 5):
        net_addr(f"q{q:03d}", n); q += 1
    for n in range(5, 8):
        host_only(f"q{q:03d}", n); q += 1
    for n in range(1, 6):
        ss_service(f"q{q:03d}", n); q += 1
    for n in range(1, 4):
        bridge(f"q{q:03d}", n); q += 1
    for n in range(4, 6):
        bond(f"q{q:03d}", n); q += 1
    for n in range(1, 4):
        ufw_q(f"q{q:03d}", n); q += 1
    for n in range(4, 7):
        nft_q(f"q{q:03d}", n); q += 1
    for n in range(1, 5):
        route_q(f"q{q:03d}", n); q += 1
    for n in range(1, 6):
        ssh_q(f"q{q:03d}", n); q += 1
    # q137 starts Storage
    for n in range(1, 7):
        partition_q(f"q{q:03d}", n); q += 1
    for n in range(1, 4):
        swap_q(f"q{q:03d}", n); q += 1
    for n in range(1, 6):
        fs_q(f"q{q:03d}", n); q += 1
    for n in range(1, 6):
        fstab_q(f"q{q:03d}", n); q += 1
    for n in range(1, 5):
        mountopt_q(f"q{q:03d}", n); q += 1
    for n in range(1, 9):
        lvm_q(f"q{q:03d}", n); q += 1
    for n in range(1, 5):
        perf_q(f"q{q:03d}", n); q += 1
    for n in range(1, 4):
        raid_q(f"q{q:03d}", n); q += 1
    # Users q175-q198
    for n in range(1, 5):
        user_local(f"q{q:03d}", n); q += 1
    for n in range(1, 4):
        group_q(f"q{q:03d}", n); q += 1
    for n in range(1, 4):
        profile_q(f"q{q:03d}", n); q += 1
    for n in range(1, 4):
        skel_q(f"q{q:03d}", n); q += 1
    for n in range(1, 4):
        ulimit_q(f"q{q:03d}", n); q += 1
    for n in range(1, 6):
        sudo_q(f"q{q:03d}", n); q += 1
    for n in range(1, 4):
        root_q(f"q{q:03d}", n); q += 1
    for idx, n in enumerate(range(1, 5), 13):
        firewalld_q(f"qR{idx:02d}", n)
    update_coverage()


if __name__ == "__main__":
    main()
