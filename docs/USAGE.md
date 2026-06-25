# Using the LFCS Exam Lab — step-by-step guide

This walks you through a full practice session and a full exam session, screen by screen.
It assumes you've already run the installer (`.\install.ps1` on Windows, `./install.sh` on
macOS/Linux) and the VMs are built. If not, see the [README](../README.md#quick-start) first.

> The screens look identical on every OS — only the launch command differs
> (`.\lfcs.ps1` on Windows, `./lfcs.sh` on macOS/Linux). The colors don't show in this
> document; they're vivid in a real terminal.

---

## 1. Launch the lab

From the repo folder:

```powershell
.\lfcs.ps1          # Windows
```
```bash
./lfcs.sh           # macOS / Linux
```

You land on the mode menu:

![Mode menu](images/01-mode-menu.png)

```
  +--------------------------------------+
  |           LFCS Exam Lab               |
  +--------------------------------------+

  [1]  Practice Mode  | free navigation | no timer | hints available
  [2]  Exam Mode      | timed 120min | 20 random questions | scored

  Select mode:
```

- **`1` Practice** — browse all 250 questions freely, no timer, hints available. Best for learning.
- **`2` Exam** — a timed, scored, random subset. Best for simulating the real test.

---

## 2. Practice mode

### 2.1 Pick a question

Type `1`. The question list appears:

![Practice question list](images/02-practice-list.png)

```
  LFCS Practice - 250 questions
  2 passed  0 failed  1 in progress  247 new
------------------------------------------------------------

  1. q001    NEW   Archive selected log files            Essential Commands       | easy   | 0 tries
  2. q002    NEW   Set permissions and create a symlink  Essential Commands       | easy   | 0 tries
  5. q005   PASS   Configure local hostname resolution   Networking               | easy   | 2 tries
  ...
  [q] quit
```

Each row shows: **number** · **question id** · **status** (`NEW` / `PASS` / `FAIL` / `····` in‑progress) ·
**title** · **domain** · **difficulty** · how many times you've tried it. Type a number and press Enter.

### 2.2 Read the task

The lab restores that VM to a clean snapshot, sets up the starting state, and shows the task:

![Question view](images/03-question-view.png)

```
  q005: Configure local hostname resolution
  Networking  | easy  | node1
------------------------------------------------------------

  Configure local name resolution so repo.lfcs.local resolves to 10.10.10.50 using /etc/hosts.

------------------------------------------------------------
  [v] validate  [s] ssh  [t] task  [r] reload  [h] hints  [q] menu
  Action:
```

The action bar is your toolbox:

| Key | Does |
|---|---|
| `s` | **SSH into the VM** to do the task |
| `v` | **Validate** your answer |
| `t` | reprint the task text |
| `r` | **reload** — reset the VM to a clean start (redo from scratch) |
| `h` | toggle **hints** |
| `q` | back to the question list |

### 2.3 Solve it — press `s`

Pressing `s` opens a shell **inside the VM** (a new window on Windows; inline on macOS/Linux):

![SSH session in the VM](images/04-ssh-session.png)

```
vagrant@lfcs-node1:~$ sudo bash -c 'echo "10.10.10.50 repo.lfcs.local" >> /etc/hosts'
vagrant@lfcs-node1:~$ getent hosts repo.lfcs.local
10.10.10.50     repo.lfcs.local
vagrant@lfcs-node1:~$ exit
```

Do the task here using real Linux commands. The task is also saved on the VM at `/root/TASK.md`.
Type `exit` when you're done to return to the lab.

> Stuck? Press `h` back in the lab for hints, or `t` to reread the task.

### 2.4 Validate — press `v`

Press `v`. The lab runs the official validator against the VM's real end state:

![Validation passed](images/05-validate-pass.png)

```
RESULT: PASS
```

- **Green `RESULT: PASS`** — solved correctly. Your progress is saved.
- **Red `RESULT: FAIL - <reason>`** — the reason tells you what's still wrong. Fix it (`s`) and validate again.

Press `r` any time to wipe the VM back to a clean start and redo the question. Press `q` to pick another.

---

## 3. Exam mode

Back at the main menu, choose `2`. You get a **timed, scored** random set:

![Exam question list](images/06-exam-list.png)

```
  Exam Mode -   119:42 remaining
  0 PASS  0 FAIL  0/20 done
------------------------------------------------------------

   1. q192    ----  Grant limited sudo to sudoer2          Users and Groups  | ubuntu
   2. q225    ----  Configure key SSH node1 to node2 1     Networking        | ubuntu
   ...
  [e] end exam
  Open question #:
```

- The header shows **time remaining** and your running **PASS / FAIL** score.
- Open a question by number, solve it with `s`, and `v` to validate — same as practice, but **no hints and no reload** (just like the real exam).
- `b` returns to the list; `e` ends the exam early.

When you finish (or time runs out) you get a **score report**:

![Exam score report](images/07-score-report.png)

```
  Exam Score Report
------------------------------------------------------------

  Result     PASS    80.0%  16/20 correct  4 failed
  Threshold : approx. 66% (not an official LFCS figure)
  Time used : 4210s  |  End: completed

  PASS  q192  Users and Groups  ubuntu
  FAIL  q225  Networking        ubuntu
  ...
```

The threshold is configurable and **not** an official LFCS score — it's just a study target. Every exam
is also saved to `data/exam-sessions.json` so you can look back at past attempts.

---

## 4. Tips

- **Progress sticks.** `progress.json` remembers pass/fail/attempts across sessions, so the practice list
  always shows where you left off.
- **Tune the exam.** Pass options to change the exam, e.g. a 30‑minute, 10‑question exam:
  ```powershell
  .\lab.ps1 -Mode Exam -ExamDurationMinutes 30 -ExamQuestionCount 10
  ```
  ```bash
  ./lfcs.sh --mode exam --exam-duration 30 --exam-count 10
  ```
- **Self-test a question** end-to-end (load → fail → solve → pass → restore):
  ```bash
  python3 lab.py --gate q005          # macOS/Linux (also works on Windows)
  ```
- **Re-check your machine** any time (changes nothing): `./install.sh --check-only` /
  `.\install.ps1 -CheckOnly`.

---

## Troubleshooting

See the [README troubleshooting section](../README.md#troubleshooting). If something's still off,
open an issue using the **Bug report** template — paste your `--check-only` output and it'll be quick to diagnose.
