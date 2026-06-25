# Screenshots for the usage guide

Drop the screenshots referenced by [`../USAGE.md`](../USAGE.md) here, using these exact filenames.
Capture them from a real terminal (the colors make the lab look great). Crop to the terminal window;
PNG preferred.

| Filename | What to capture | How to get the screen |
|---|---|---|
| `01-mode-menu.png` | The main mode menu | Launch `.\lfcs.ps1` / `./lfcs.sh` |
| `02-practice-list.png` | The practice question list | Mode menu → press `1` |
| `03-question-view.png` | A loaded question with the action bar | Practice → open a question (e.g. `5` for q005) |
| `04-ssh-session.png` | The shell inside the VM after solving | In a question, press `s`, run a couple of commands |
| `05-validate-pass.png` | A green `RESULT: PASS` after validating | Solve the question, then press `v` |
| `06-exam-list.png` | The timed exam list with the score header | Main menu → press `2` |
| `07-score-report.png` | The end-of-exam score report | Finish or end an exam (`e`) |

Tip: q005 ("Configure local hostname resolution") is a quick, reliable one to use for shots 03–05 —
solve it with `sudo bash -c 'echo "10.10.10.50 repo.lfcs.local" >> /etc/hosts'`.

Until the images are added, the guide still reads fine: each screenshot is followed by a text version of
the same screen.
