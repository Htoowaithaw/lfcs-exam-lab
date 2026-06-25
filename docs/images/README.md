# Screenshots for the usage guide

The visuals in [`../USAGE.md`](../USAGE.md) are **terminal-style SVG renderings** of each screen (committed
here as `01-mode-menu.svg` … `07-score-report.svg`). They reproduce the lab's real colored UI without
needing photos, so the guide is illustrated out of the box and renders crisply at any size.

## Want real photo screenshots instead?

You can replace any SVG with an actual capture from your own terminal — just keep the base filename and use
`.svg` or change the reference in `USAGE.md` to `.png`. Capture guide:

| File | What to capture | How to get the screen |
|---|---|---|
| `01-mode-menu` | The main mode menu | Launch `.\lfcs.ps1` / `./lfcs.sh` |
| `02-practice-list` | The practice question list | Mode menu → press `1` |
| `03-question-view` | A loaded question with the action bar | Practice → open a question (e.g. `5` for q005) |
| `04-ssh-session` | The shell inside the VM after solving | In a question, press `s`, run a couple of commands |
| `05-validate-pass` | A green `RESULT: PASS` after validating | Solve the question, then press `v` |
| `06-exam-list` | The timed exam list with the score header | Main menu → press `2` |
| `07-score-report` | The end-of-exam score report | Finish or end an exam (`e`) |

Tip: q005 ("Configure local hostname resolution") is a quick one for shots 03–05 — solve it with
`sudo bash -c 'echo "10.10.10.50 repo.lfcs.local" >> /etc/hosts'`.
