# LFCS Exam Lab

[![CI](https://github.com/Htoowaithaw/lfcs-exam-lab/actions/workflows/ci.yml/badge.svg)](https://github.com/Htoowaithaw/lfcs-exam-lab/actions/workflows/ci.yml)

A free, local, hands-on practice lab for the **Linux Foundation Certified System Administrator (LFCS)**
exam. **250 real tasks** on disposable Linux VMs, with automated validation, a free-navigation **practice
mode**, and a timed, scored **exam mode**.

Every question restores a clean VM snapshot, injects only the starting condition, and lets you solve the
task in a real shell — then a validator checks the actual end state (values, ownership, modes, services,
ports, filesystems, persistence). It runs **offline** after setup.

> The repetition is intentional: many questions are close variants of the same operation, so you build the
> muscle memory that makes the real exam fast.

## Disclaimer

- **This is not an exam dump.** Every task here is **original practice material** written for this lab. It
  contains no real, leaked, or memorized LFCS exam questions. Brain dumps violate the Linux Foundation's
  Candidate Agreement — this project is a skills trainer, not a shortcut around it.
- **No guarantee you'll pass.** This lab builds hands-on skill and speed; it does **not** promise an exam
  pass. Your result depends on your own study and practice.
- **Not affiliated.** This is an independent project, **not affiliated with, endorsed by, or sponsored by
  the Linux Foundation**. "LFCS" and "Linux Foundation Certified System Administrator" are trademarks of the
  Linux Foundation, used here only to describe what the lab helps you practice for.
- The exam-mode score and pass threshold are **approximate and unofficial** — not an LFCS score.

## Quick start

You need an **x86-64** machine (Windows / Linux / Intel Mac) with virtualization enabled. The installer
checks everything first and can install the prerequisites for you.

**Windows (PowerShell):**
```powershell
git clone https://github.com/Htoowaithaw/lfcs-exam-lab.git
cd lfcs-exam-lab
.\install.ps1            # preflight -> install Vagrant/VirtualBox -> build VMs -> self-verify
.\lfcs.ps1              # start practicing
```

**Linux / Intel macOS (bash):**
```bash
git clone https://github.com/Htoowaithaw/lfcs-exam-lab.git
cd lfcs-exam-lab
./install.sh            # preflight -> install Vagrant/VirtualBox -> build VMs -> self-verify
./lfcs.sh              # start practicing
```

**Just check if your machine is ready (changes nothing):**
```bash
./install.sh --check-only      # or:  .\install.ps1 -CheckOnly
```

The installer detects your OS, CPU virtualization, RAM and disk; warns about a conflicting hypervisor
(Hyper-V / WSL2 / KVM); installs Vagrant + VirtualBox (+ python3 on Mac/Linux) if missing; builds the three
VMs; and finally **self-verifies** by running one real question end-to-end. If that passes, your machine is
good — you don't have to take our word for it.

## Platform support

| Platform | Status | Notes |
|---|---|---|
| **Windows x86-64** | ✅ Supported — installer + lab self-verified on a Win11 dev machine | VirtualBox 7+ coexists with Hyper-V (slower); installer offers to disable it |
| **Linux x86-64** | 🧪 Built; not yet verified on a clean machine — feedback/PRs welcome | `apt`/`dnf` install path; needs VT-x/AMD-V and no active KVM guest |
| **Intel Mac x86-64** | 🧪 Built; not yet verified on a clean machine — feedback/PRs welcome | `brew` install path |
| **Apple Silicon Mac (M1/M2/M3/M4)** | ❌ Not supported | VirtualBox cannot run the x86 Ubuntu/Rocky VMs this lab uses; no workaround on ARM |

Every install runs a built-in self-verify (`lab.py --gate q005` / the Windows gate), so even on the
"not yet verified" platforms you get an immediate pass/fail for your own machine. If something is off on your
OS, please open an issue with your `--check-only` output.

## Requirements

- **x86-64** CPU with hardware virtualization (VT-x / AMD-V) enabled in BIOS/UEFI
- **RAM:** 8 GB minimum (runs node1+node2), 16 GB+ recommended (comfortable headroom for all three VMs)
- **Disk:** ~30 GB free minimum, ~50 GB recommended (VM images + node1's scratch disks)
- **Tools:** Vagrant + VirtualBox (the installer can add them); `python3` on macOS/Linux (preinstalled or
  added by the installer)
- No conflicting hypervisor actively holding the CPU's virtualization (Hyper-V/WSL2 on Windows, a running
  KVM guest on Linux). VirtualBox 7+ often coexists; the installer will tell you.

## Question bank

| Domain | Questions |
|---|---:|
| Essential Commands | 50 |
| Operations & Deployment | 60 |
| Networking | 60 |
| Storage | 50 |
| Users and Groups | 30 |

**Total: 250** — 215 single-node, 35 two-node. Single-node Ubuntu tasks run on `node1` (`lfcs-node1`),
Rocky Linux tasks on `lfcs-rocky1`, and two-node tasks use `node1` + `node2` over the host-only network
`192.168.56.0/24`. See `docs/BANK_COVERAGE.md`.

The VMs built by setup:

- `node1` — Ubuntu 22.04, 4 GB, 2 vCPU, `192.168.56.11` (+ 8 scratch disks for storage tasks)
- `node2` — Ubuntu 22.04, 3 GB, 2 vCPU, `192.168.56.12`
- `lfcs-rocky1` — Rocky Linux 9, 4 GB, 2 vCPU

## Usage

Start the lab with `.\lfcs.ps1` (Windows) or `./lfcs.sh` (Mac/Linux). The menu offers:

- **Practice Mode** — browse the full list freely, no timer, hints available.
- **Exam Mode** — timed, random question set, scored against a configurable (approximate, unofficial)
  threshold.

In a question:

- `s` — SSH into the target VM (for two-node questions, pick which VM)
- `v` — validate your answer
- `t` — reprint the task text
- `r` — reload/reset the question from the clean base (practice mode)
- `h` — toggle hints (practice mode)
- `b` / `q` — back / quit

The task is also written to `/root/TASK.md` (and shown at shell login) on the target VM.

## Manual setup (advanced)

If you already have Vagrant + VirtualBox and prefer to build directly:

```powershell
# Windows
powershell -ExecutionPolicy Bypass -File .\setup.ps1            # build + base snapshots
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -Rebuild   # force rebuild
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -DryRun    # preview, no changes
```

`setup.ps1` builds the three VMs, saves exactly one `base` snapshot per VM, builds `.ssh-cache.json`, and
verifies node1↔node2 connectivity. It skips VMs that already have a `base` snapshot. (`install.ps1` calls
this for you and adds preflight + tool install + self-verify around it.)

## Architecture

Restore-base → inject → solve → validate:

1. Restore the target VM(s) to the `base` snapshot.
2. Run the matching `inject/` script (sets the starting state; network-free; never contains the solution).
3. Present the task.
4. Validate the final state with the matching `validate/` script.

**Validation contract:** `validate/<qid>.sh` runs as root in the target VM; exit `0` = PASS, non-zero =
FAIL; the final stdout line is exactly `RESULT: PASS` or `RESULT: FAIL - <reason>`.

Each question has four files:

- `questions/<qid>.yaml` — task text, domain, topic, difficulty, distro, vms, hints
- `inject/<qid>.sh`
- `validate/<qid>.sh`
- `solution/<qid>.sh` — reference answer; must make its own validator pass

Two-VM questions use per-node scripts: `inject/<qid>.node1.sh`, `inject/<qid>.node2.sh`,
`solution/<qid>.node1.sh`, `solution/<qid>.node2.sh`. Validation runs on the primary VM and checks both
nodes. Distro routing comes from the YAML: `distro: ubuntu` → `node1` (unless `vms:` lists more);
`distro: rocky` → `lfcs-rocky1`.

The launcher exists in two forms with identical behavior: `lab.ps1` (Windows PowerShell) and `lab.py`
(Python 3, used on macOS/Linux). Both read the same `questions/`, write the same `progress.json` /
`data/exam-sessions.json`, and use the same Vagrant + VirtualBox backend.

## Verifying a question (self-test / gate)

Run a single question end-to-end (load → unsolved-fails → solve → solved-passes → restore):

```bash
python3 lab.py --gate q005                 # macOS / Linux (also works on Windows)
```
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_question_gate.ps1 -QuestionIds q005
```

A pass prints `q005 PASS/PASS/PASS/PASS` and exits 0. This is exactly what the installer's self-verify runs.

## Troubleshooting

- **Slow loads / VMs won't start:** usually low RAM, slow disk, or a conflicting hypervisor holding
  virtualization. Close heavy apps; on Windows let the installer disable Hyper-V/WSL2 (needs a reboot); on
  Linux stop any running KVM guest. Confirm VT-x/AMD-V is enabled in BIOS.
- **Re-check readiness anytime:** `./install.sh --check-only` (or `.\install.ps1 -CheckOnly`).
- **A VM is stuck:** reload the question (restores its base), or rebuild with `setup.ps1 -Rebuild`.
- **SSH key permission complaints (Windows):** keep the repo in your user profile; don't copy `.vagrant/`
  or `.ssh-cache.json` between machines.

## Contributing

Add one question at a time with the four-file pattern above. For two-VM questions, use the per-node
convention: `inject/<qid>.node1.sh`, `inject/<qid>.node2.sh`, `solution/<qid>.node1.sh`,
`solution/<qid>.node2.sh` (validation runs on the primary node and checks both). Keep inject scripts
network-free and solution-free;
validators must check the real end state (exact values, ownership, modes, persistence, services, ports,
routes, filesystems, and any "only/exactly" constraints).

Gate before committing — it must show load PASS, unsolved FAIL, solved PASS, restore PASS:

```bash
python3 lab.py --gate q234
```

**Platform testing help wanted:** the Linux and Intel-macOS install paths are written but not yet verified
on clean machines. If you run `install.sh` on a fresh Linux or Intel Mac, please open an issue with your
`./install.sh --check-only` output and whether the self-verify passed.
