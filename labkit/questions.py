"""Question discovery and parsing.

Hand-parses the simple, fixed-shape question YAML used by this bank so we don't
need PyYAML (zero dependencies = friction-free `git clone` + run). This mirrors
the `Read-Question` / `Get-Questions` functions in `lab.ps1` exactly so both
launchers see an identical question set.

Question file shape (questions/<qid>.yaml):

    id: q159
    title: "Mount filesystem with noatime"
    domain: "Storage"
    topic: "mount options"
    difficulty: medium
    distro: ubuntu
    vms: [node1]
    question: |
      <two-space-indented body, possibly multiple lines>
    hints: ["first hint", "second hint"]
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import List


@dataclass
class Question:
    id: str = ""
    title: str = ""
    domain: str = ""
    topic: str = ""
    difficulty: str = ""
    distro: str = "ubuntu"
    vms: List[str] = field(default_factory=list)
    question: str = ""
    hints: List[str] = field(default_factory=list)
    path: Path = None  # type: ignore[assignment]

    def machines(self) -> List[str]:
        """Target VMs for this question (mirrors Get-QuestionMachines).

        Explicit `vms:` wins; otherwise infer from distro (rocky -> lfcs-rocky1,
        anything else -> node1).
        """
        if self.vms:
            return [m.strip() for m in self.vms if m.strip()]
        if (self.distro or "ubuntu").lower() == "rocky":
            return ["lfcs-rocky1"]
        return ["node1"]

    def target_machine(self) -> str:
        """Primary VM (where validation runs). Mirrors Get-TargetMachine."""
        machines = self.machines()
        if machines:
            return machines[0]
        return "lfcs-rocky1" if (self.distro or "ubuntu").lower() == "rocky" else "node1"


def _strip(value: str) -> str:
    """Trim surrounding whitespace and a single pair of quotes, like .Trim('\" ')."""
    return value.strip().strip('"').strip()


def parse_question(path: Path) -> Question:
    lines = Path(path).read_text(encoding="utf-8").splitlines()
    q = Question(path=Path(path))
    i = 0
    while i < len(lines):
        line = lines[i]
        m = re.match(r"^id:\s*(.+)$", line)
        if m:
            q.id = _strip(m.group(1))
            i += 1
            continue
        m = re.match(r"^title:\s*(.+)$", line)
        if m:
            q.title = _strip(m.group(1))
            i += 1
            continue
        m = re.match(r"^domain:\s*(.+)$", line)
        if m:
            q.domain = _strip(m.group(1))
            i += 1
            continue
        m = re.match(r"^topic:\s*(.+)$", line)
        if m:
            q.topic = _strip(m.group(1))
            i += 1
            continue
        m = re.match(r"^difficulty:\s*(.+)$", line)
        if m:
            q.difficulty = _strip(m.group(1))
            i += 1
            continue
        m = re.match(r"^distro:\s*(.+)$", line)
        if m:
            q.distro = _strip(m.group(1))
            i += 1
            continue
        m = re.match(r"^vms:\s*\[(.*)\]\s*$", line)
        if m:
            q.vms = [p.strip().strip('"').strip() for p in m.group(1).split(",") if p.strip()]
            i += 1
            continue
        if re.match(r"^question:\s*\|", line):
            buf: List[str] = []
            i += 1
            while i < len(lines):
                bm = re.match(r"^\s{2}(.*)$", lines[i])
                if not bm:
                    break
                buf.append(bm.group(1))
                i += 1
            q.question = "\n".join(buf)
            continue
        m = re.match(r"^hints:\s*\[(.*)\]\s*$", line)
        if m:
            items = m.group(1)
            if items.strip():
                # Split on the `", "` boundary between hints, then strip stray
                # quotes/brackets — mirrors the lab.ps1 hint parser.
                parts = re.split(r'",\s*"', items)
                q.hints = [p.strip().strip('"').strip("[").strip("]") for p in parts]
            i += 1
            continue
        i += 1

    if not q.id.strip():
        raise ValueError(f"Question file '{path}' has no id")
    return q


def _sort_key(q: Question):
    """Order q001..q234 numerically, then qR01..qR16, like lab.ps1's sort."""
    m = re.match(r"^qR(\d+)$", q.id)
    if m:
        return (10000 + int(m.group(1)), q.id)
    m = re.match(r"^q(\d+)$", q.id)
    if m:
        return (int(m.group(1)), q.id)
    return (99999, q.id)


def load_questions(lab_root: Path) -> List[Question]:
    qdir = Path(lab_root) / "questions"
    if not qdir.is_dir():
        raise FileNotFoundError(f"No questions directory at {qdir}")
    qs = [parse_question(p) for p in qdir.glob("*.yaml")]
    qs.sort(key=_sort_key)
    return qs
