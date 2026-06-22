# Security Policy

## What this project is

The LFCS Exam Lab is a **local, offline practice environment**. It builds disposable VirtualBox VMs with
Vagrant and runs practice tasks inside them. It is **not** a network service — nothing in this project
listens for inbound connections, and running it does not expose your machine to the network.

## Trust boundary (important)

The lab has a deliberate isolation boundary between the **host** and the **VMs**:

- **Question scripts run only inside the VMs.** Every `inject/<qid>.sh`, `validate/<qid>.sh`, and
  `solution/<qid>.sh` is executed as root **inside a disposable VM** over SSH (`sudo bash /vagrant/...`).
  They never run on your host. Any change they make is wiped when the VM is restored to its `base`
  snapshot, which happens every time a question is loaded.
- **The host runs only fixed orchestration.** The launchers (`lab.ps1`, `lab.py`), installers
  (`install.ps1`, `install.sh`), `setup.ps1`, and `scripts/run_question_gate.ps1` invoke a fixed set of
  commands (`vagrant`, `VBoxManage`, `ssh`, and the OS package manager). They do **not** evaluate question
  content: task text is displayed on the host and decoded only inside the VM, so question data cannot inject
  code onto the host.

**Consequence:** a malicious or buggy *question* script can, at worst, damage a throwaway VM that you
rebuild in minutes. It cannot reach your host.

## What is NOT in this repository

- No private keys, certificates, tokens, or passwords for any real system.
- Your runtime state never ships: `.vagrant/`, `.ssh-cache.json`, `progress.json`, and
  `data/exam-sessions.json` are git-ignored.
- Some questions set **known, throwaway credentials inside the disposable VMs** (e.g. a fixed root password
  for a password-recovery exercise, or an LDAP `admin` bind password). These are part of the exercises and
  exist only inside ephemeral VMs — they are not secrets and grant no access to anything outside the lab.

## SSH configuration note

Connections to the lab VMs use `StrictHostKeyChecking=no` with `UserKnownHostsFile=/dev/null` (or `NUL` on
Windows). This is intentional: the VMs are ephemeral and reachable only over loopback-forwarded ports and
the host-only network `192.168.56.0/24`, and they are rebuilt on reused ports, so host-key pinning would
only cause spurious failures. These connections are never exposed to an untrusted network.

## For contributors and anyone reviewing a fork/PR

Because of the trust boundary above, review effort should focus where code runs **on the host**:

- **Host-side (review carefully before running/merging):** `Vagrantfile` (Ruby, evaluated on the host by
  `vagrant up`), `install.ps1`, `install.sh`, `lab.ps1`, `lab.py`, `labkit/**`, `setup.ps1`, `lfcs.ps1`,
  `lfcs.sh`, `scripts/*.ps1`.
- **VM-sandboxed (lower risk — runs only in a disposable VM):** `inject/**`, `validate/**`, `solution/**`,
  `provision*.sh`.

Inject scripts must stay network-free and must never contain the solution.

## Reporting a vulnerability

If you find a security issue, please open an issue describing it (or, for anything sensitive, contact the
maintainer directly rather than filing a public issue). Include the file involved and how to reproduce.
