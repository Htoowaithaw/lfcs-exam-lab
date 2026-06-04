# LFCS Exam Lab

A free local LFCS practice lab for Windows hosts using VirtualBox and Vagrant. It includes 250 hands-on tasks, automated validation, practice mode, and timed exam mode.

The lab is built around disposable VM state: every question restores a clean base snapshot, injects only the starting condition, and then lets you solve the task inside the VM.

## Question Bank

The bank follows the five LFCS domains tracked in `docs/BANK_COVERAGE.md`.

| Domain | Questions |
|---|---:|
| Essential Commands | 50 |
| Operations & Deployment | 60 |
| Networking | 60 |
| Storage | 50 |
| Users and Groups | 30 |

Total: 250 questions.

There are 215 single-node questions and 35 two-node questions. Single-node Ubuntu tasks run on `node1` (`lfcs-node1`), Rocky Linux tasks run on `lfcs-rocky1`, and two-node tasks use `node1` plus `node2` over the host-only network `192.168.56.0/24`.

## Host Requirements

- Windows 11
- VirtualBox
- Vagrant
- 16 GB RAM minimum, 32 GB recommended
- NVMe storage strongly recommended
- Enough disk space for three VM bases and scratch disks. Expect roughly a few GB per base snapshot plus VirtualBox VM storage.

## Setup

From this repository:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1
```

The first run builds all three VMs:

- `node1`: Ubuntu 22.04, 4 GB RAM, 2 vCPU, host-only IP `192.168.56.11`
- `node2`: Ubuntu 22.04, 3 GB RAM, 2 vCPU, host-only IP `192.168.56.12`
- `lfcs-rocky1`: Rocky Linux 9, 4 GB RAM, 2 vCPU

Setup provisions the base packages, saves exactly one snapshot named `base` for each VM, builds `.ssh-cache.json`, and verifies node1-to-node2 connectivity. It skips existing base snapshots by default. To intentionally rebuild the lab VMs, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -Rebuild
```

To preview setup decisions without changing VM state:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -DryRun
```

Provisioning pre-stages the offline dependencies needed by the question bank: local apt/dnf repositories, a local Docker base image, source tarballs, libvirt XML, NFS/NBD/chrony/LDAP tooling, storage utilities, and common LFCS command-line tools. After setup, question inject and solution scripts do not need internet access.

## Usage

Launch the lab:

```powershell
.\lab.ps1
```

The startup menu offers:

- Practice Mode: browse the question list freely with no timer.
- Exam Mode: timed random question set with scoring.

Question actions:

- `s`: SSH into the target VM. For two-node questions, choose which VM to enter.
- `v`: validate your current answer.
- `t`: reprint the task text in the lab terminal.
- `r`: reload/reset the current question from the clean base, where available.
- `b` or `q`: go back or quit, depending on the menu.

When a question loads, the launcher writes the task to `/root/TASK.md` on the target VM or VMs and displays it at shell login, so the task is visible after pressing `s`.

Exam mode uses configurable duration, question count, threshold, and seed parameters. The pass threshold is approximate and configurable, not an official LFCS score.

## Architecture

The lab uses a restore-base-then-inject model:

1. Restore the target VM or VMs to the `base` snapshot.
2. Run the matching inject script from `inject/`.
3. Present the task.
4. Validate the final state with the matching script from `validate/`.

Validation contract:

- `validate/<qid>.sh` runs as root inside the target VM.
- Exit code `0` means PASS.
- Any non-zero exit code means FAIL.
- The final stdout line must be exactly `RESULT: PASS` or `RESULT: FAIL - <reason>`.

Each question normally has four files:

- `questions/<qid>.yaml`
- `inject/<qid>.sh`
- `validate/<qid>.sh`
- `solution/<qid>.sh`

Two-VM questions use per-VM scripts where needed:

- `inject/<qid>.node1.sh`
- `inject/<qid>.node2.sh`
- `solution/<qid>.node1.sh`
- `solution/<qid>.node2.sh`

For multi-VM questions, validation runs on the primary VM, usually `node1`, and checks the end-to-end state across both nodes.

Distro routing is driven by question YAML. `distro: ubuntu` routes to `node1` unless the question lists multiple VMs. `distro: rocky` routes to `lfcs-rocky1`.

## Troubleshooting

Slow loads usually mean the host is short on RAM or storage I/O. Close other heavy applications, make sure the laptop is plugged in, and avoid running all VMs plus other hypervisors at the same time.

If a lab VM gets stuck, restore its base snapshot through the launcher by reloading the question, or use `setup.ps1 -DryRun` to confirm the expected base snapshots still exist.

If SSH fails, rebuild the cache by running:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -DryRun
```

Then run normal setup if the cache is missing:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1
```

If Windows or OpenSSH complains about key permissions, keep the repo in your user profile and avoid copying `.vagrant/` or `.ssh-cache.json` between machines.

## Contributing

Add one question at a time using the four-file pattern:

1. `questions/<qid>.yaml`
2. `inject/<qid>.sh`
3. `validate/<qid>.sh`
4. `solution/<qid>.sh`

For two-VM questions, use the `.node1.sh` and `.node2.sh` convention documented in `docs/MULTIVM_CONVENTION.md`.

Keep inject scripts network-free and never put the solution into the inject script. Validators should check the real end state, including exact values, ownership, modes, persistence, service state, ports, routes, filesystems, and "only/exactly" constraints stated in the task.

Gate a question before committing:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_question_gate.ps1 -QuestionIds q234 -OutputPath gate-results.json
```

The gate must show load PASS, unsolved validation FAIL, solved validation PASS, and restore PASS.
