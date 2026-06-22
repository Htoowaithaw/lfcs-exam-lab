#!/usr/bin/env bash
# lfcs.sh - friendly entry point for the LFCS Exam Lab (macOS / Linux).
# Thin wrapper around the Python launcher so users just run:  ./lfcs.sh
# All arguments pass straight through to lab.py.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 not found. Run ./install.sh first (it can install it)." >&2
  exit 1
fi
if [ ! -f "$here/lab.py" ]; then
  echo "lab.py not found next to lfcs.sh - is the repo intact?" >&2
  exit 1
fi
exec python3 "$here/lab.py" "$@"
