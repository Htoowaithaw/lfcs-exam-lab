"""Parity self-check: prove the parser sees the question bank correctly.

This is the permanent CI gate (run by .github/workflows/ci.yml on every push/PR
across Windows/Linux/macOS). Run locally with: python -m labkit._parity_check
Validates total count, domain distribution, multi-VM count, and that every
question parsed with a non-empty id/title/question + resolvable target machine.
"""

from collections import Counter
from pathlib import Path

from labkit.questions import load_questions

EXPECTED_DOMAINS = {
    "Essential Commands": 50,
    "Operations & Deployment": 60,
    "Networking": 60,
    "Storage": 50,
    "Users and Groups": 30,
}


def main() -> int:
    root = Path(__file__).resolve().parent.parent
    qs = load_questions(root)

    domains = Counter(q.domain for q in qs)
    multivm = [q for q in qs if len(q.machines()) > 1]
    rocky = [q for q in qs if q.id.startswith("qR")]
    bad = [q for q in qs if not (q.id and q.title and q.question and q.target_machine())]

    print(f"total questions      : {len(qs)}  (expected 250)")
    print(f"multi-VM questions   : {len(multivm)}  (expected 35)")
    print(f"rocky (qR*) questions: {len(rocky)}  (expected 16)")
    print("domains:")
    for name, exp in EXPECTED_DOMAINS.items():
        got = domains.get(name, 0)
        flag = "OK" if got == exp else "MISMATCH"
        print(f"  {name:<26} {got:>3}  (expected {exp})  [{flag}]")
    extra = set(domains) - set(EXPECTED_DOMAINS)
    if extra:
        print(f"  UNEXPECTED DOMAINS: {sorted(extra)}")
    if bad:
        print(f"PARSE PROBLEMS in {len(bad)} questions: {[q.id for q in bad][:10]}")

    ok = (
        len(qs) == 250
        and len(multivm) == 35
        and domains == Counter(EXPECTED_DOMAINS)
        and not bad
    )
    print()
    print("PARITY OK" if ok else "PARITY FAILED")

    # Spot-check the trickiest parses.
    by_id = {q.id: q for q in qs}
    q225 = by_id.get("q225")
    if q225:
        print(f"\nspot q225 vms={q225.vms} hints={len(q225.hints)} "
              f"qlen={len(q225.question)}")
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
