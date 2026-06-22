"""Runtime state: per-question progress and saved exam sessions.

Same on-disk files and shapes as lab.ps1 (progress.json, data/exam-sessions.json)
so the two launchers share history.
"""

from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


class Progress:
    def __init__(self, path: Path):
        self.path = Path(path)
        self.data: Dict[str, dict] = {}
        self._load()

    def _load(self) -> None:
        if not self.path.exists():
            return
        try:
            raw = self.path.read_text(encoding="utf-8").strip()
            if raw:
                self.data = json.loads(raw)
        except (OSError, json.JSONDecodeError):
            self.data = {}

    def save(self) -> None:
        self.path.write_text(json.dumps(self.data, indent=2), encoding="utf-8")

    def status(self, qid: str) -> str:
        entry = self.data.get(qid)
        return entry.get("status", "new") if isinstance(entry, dict) else "new"

    def attempts(self, qid: str) -> int:
        entry = self.data.get(qid)
        return int(entry.get("attempts", 0)) if isinstance(entry, dict) else 0

    def update(self, qid: str, status: str, count_attempt: bool) -> None:
        attempts = self.attempts(qid)
        if count_attempt:
            attempts += 1
        self.data[qid] = {
            "status": status,
            "attempts": attempts,
            "last_ts": _now_iso(),
        }
        self.save()


class ExamSessions:
    def __init__(self, path: Path):
        self.path = Path(path)
        self.path.parent.mkdir(parents=True, exist_ok=True)
        if not self.path.exists():
            self.path.write_text("[]", encoding="utf-8")

    def append(self, session: dict) -> None:
        try:
            existing = json.loads(self.path.read_text(encoding="utf-8") or "[]")
            if not isinstance(existing, list):
                existing = []
        except (OSError, json.JSONDecodeError):
            existing = []
        existing.append(session)
        self.path.write_text(json.dumps(existing, indent=2), encoding="utf-8")
