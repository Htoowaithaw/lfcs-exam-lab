#!/usr/bin/env python3
"""LFCS Exam Lab - cross-platform launcher (Linux / macOS / Windows).

A dependency-free Python port of lab.ps1 for non-Windows hosts (and anyone who
prefers it). Same question bank, same Vagrant + VirtualBox backend, same on-disk
progress/exam state. The Windows PowerShell launcher (lab.ps1) is unchanged.

Usage:
    python3 lab.py                 # interactive mode menu
    python3 lab.py --mode practice
    python3 lab.py --mode exam
    python3 lab.py --list          # print the practice list and exit (no VMs)

Run `python3 lab.py --help` for all options.
"""

from __future__ import annotations

import argparse
import random
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

from labkit import runner, ui
from labkit.providers import get_provider
from labkit.questions import Question, load_questions
from labkit.state import ExamSessions, Progress

LAB_ROOT = Path(__file__).resolve().parent


def _prompt(text: str) -> str:
    try:
        return input(text)
    except (EOFError, KeyboardInterrupt):
        print()
        return "q"


# ---- practice mode -----------------------------------------------------------

def _show_question_menu(questions, progress: Progress):
    n_pass = sum(1 for q in questions if progress.status(q.id) == "pass")
    n_fail = sum(1 for q in questions if progress.status(q.id) == "fail")
    n_tried = sum(1 for q in questions if progress.status(q.id) == "attempted")
    n_new = len(questions) - n_pass - n_fail - n_tried
    sub = (f"{ui.c('1;92', str(n_pass) + ' passed')}  "
           f"{ui.c('1;91', str(n_fail) + ' failed')}  "
           f"{ui.c('93', str(n_tried) + ' in progress')}  "
           f"{ui.c('90', str(n_new) + ' new')}")
    ui.section_header(f"LFCS Practice - {len(questions)} questions", sub)
    print()
    for i, q in enumerate(questions, 1):
        badge = ui.status_badge(progress.status(q.id))
        diff = ui.diff_badge(q.difficulty)
        tries = ui.c("90", f"| {progress.attempts(q.id)} tries")
        print(f"{i:>3}. {ui.c('97', q.id)}  {badge}  {q.title}  "
              f"{ui.c('36', q.domain)}  {ui.c('90', '|')} {diff}  {tries}")
    print()
    print(f"  {ui.c('90', '[q]')} quit")


def start_practice(provider, questions, progress: Progress):
    while True:
        _show_question_menu(questions, progress)
        choice = _prompt("  Select a question: ").strip()
        if choice == "q":
            break
        if not choice.isdigit() or not (1 <= int(choice) <= len(questions)):
            print(ui.c("91", "  Invalid choice"))
            continue
        current = questions[int(choice) - 1]
        if not runner.load_question(provider, LAB_ROOT, current, progress):
            _prompt("  Press Enter")
            continue
        _practice_question_loop(provider, current, progress)


def _practice_question_loop(provider, current: Question, progress: Progress):
    show_hints = False
    while True:
        ui.clear_screen()
        targets = ", ".join(current.machines())
        diff = ui.diff_badge(current.difficulty)
        print()
        print(f"  {ui.c('1;97', current.id + ': ' + current.title)}")
        print(f"  {ui.c('36', current.domain)}  {ui.c('90', '|')} {diff}  "
              f"{ui.c('90', '| ' + targets)}")
        print(ui.rule())
        print()
        print(current.question)
        if show_hints:
            print()
            print(ui.c("93", "  Hints:"))
            for h in current.hints:
                print(ui.c("90", f"   - {h}"))
        print()
        print(ui.rule())
        print(f"  {ui.c('1;97', '[v]')} validate  {ui.c('1;97', '[s]')} ssh  "
              f"{ui.c('1;97', '[t]')} task  {ui.c('1;97', '[r]')} reload  "
              f"{ui.c('1;97', '[h]')} hints  {ui.c('90', '[q]')} menu")
        action = _prompt("  Action: ").strip()
        if action == "v":
            print()
            try:
                runner.validate_question(provider, current, progress)
            except Exception as exc:  # noqa: BLE001 - keep the session alive on a VM/SSH failure
                print(ui.c("91", f"  Validation could not run: {exc}"))
            print()
            _prompt("  Press Enter")
        elif action == "s":
            provider.interactive_shell(_select_ssh_machine(current))
        elif action == "t":
            print()
            print(runner.format_task_text(current))
            _prompt("  Press Enter")
        elif action == "r":
            runner.load_question(provider, LAB_ROOT, current, progress)
        elif action == "h":
            show_hints = not show_hints
        elif action == "q":
            break


def _select_ssh_machine(q: Question) -> str:
    machines = q.machines()
    if len(machines) <= 1:
        return machines[0]
    print("  Select VM:")
    for i, m in enumerate(machines, 1):
        print(f"   {i}. {m}")
    choice = _prompt("  VM: ").strip()
    if choice.isdigit() and 1 <= int(choice) <= len(machines):
        return machines[int(choice) - 1]
    print(ui.c("90", f"  Using {machines[0]}"))
    return machines[0]


# ---- exam mode ---------------------------------------------------------------

def _remaining_text(end_ts: float) -> str:
    remaining = max(0, int(end_ts - time.time()))
    return f"{remaining // 60:02d}:{remaining % 60:02d}"


def start_exam(provider, questions, progress: Progress, args):
    count = min(args.exam_count, len(questions))
    rng = random.Random(args.seed) if args.use_seed else random.Random()
    selected = rng.sample(questions, count)
    started = time.time()
    end_ts = started + args.exam_duration * 60
    results = {q.id: "UNVALIDATED" for q in selected}

    sub = (f"{ui.c('97', str(len(selected)) + ' questions')}  "
           f"{ui.c('90', f'| {args.exam_duration}min | threshold ~{args.threshold}% (not official) | re-opening a question resets that VM')}")
    ui.section_header("Exam Mode", sub)

    while True:
        if time.time() >= end_ts:
            return _finish_exam(selected, results, started, "timeout", args)
        ui.clear_screen()
        n_done = sum(1 for r in results.values() if r != "UNVALIDATED")
        n_pass = sum(1 for r in results.values() if r == "PASS")
        n_fail = sum(1 for r in results.values() if r == "FAIL")
        score = (f"{ui.c('1;92', str(n_pass) + ' PASS')}  "
                 f"{ui.c('1;91', str(n_fail) + ' FAIL')}  "
                 f"{ui.c('90', f'{n_done}/{len(selected)} done')}")
        ui.section_header(f"Exam Mode - {ui.c('93', '  ' + _remaining_text(end_ts) + ' remaining')}", score)
        print()
        for i, q in enumerate(selected, 1):
            rb = ui.exam_result_badge(results[q.id])
            distro = q.distro or "ubuntu"
            print(f"  {i:>2}. {ui.c('97', q.id)}  {rb}  {q.title}  "
                  f"{ui.c('36', q.domain)}  {ui.c('90', '| ' + distro)}")
        print()
        print(f"  {ui.c('90', '[e]')} end exam")
        if all(r != "UNVALIDATED" for r in results.values()):
            return _finish_exam(selected, results, started, "completed", args)
        choice = _prompt("  Open question #: ").strip()
        if choice == "e":
            return _finish_exam(selected, results, started, "completed", args)
        if not choice.isdigit() or not (1 <= int(choice) <= len(selected)):
            print(ui.c("91", "  Invalid choice"))
            continue
        current = selected[int(choice) - 1]
        print(ui.c("90", f"  Opening {current.id} - VM resets to base snapshot..."))
        if not runner.load_question(provider, LAB_ROOT, current, progress):
            _prompt("  Press Enter")
            continue
        _exam_question_loop(provider, current, results, end_ts, started, selected, args, progress)
        if time.time() >= end_ts:
            return _finish_exam(selected, results, started, "timeout", args)


def _exam_question_loop(provider, current, results, end_ts, started, selected, args, progress):
    while True:
        if time.time() >= end_ts:
            return
        ui.clear_screen()
        diff = ui.diff_badge(current.difficulty)
        tgts = ui.c("90", "| " + ", ".join(current.machines()))
        print()
        print(f"  {ui.c('1;97', current.id + ': ' + current.title)}  "
              f"{ui.c('93', '  ' + _remaining_text(end_ts))}")
        print(f"  {ui.c('36', current.domain)}  {ui.c('90', '|')} {diff}  {tgts}")
        print(ui.rule())
        print()
        print(current.question)
        print()
        print(ui.rule())
        print(f"  {ui.c('1;97', '[v]')} validate  {ui.c('1;97', '[s]')} ssh  "
              f"{ui.c('1;97', '[t]')} task  {ui.c('90', '[b]')} back")
        action = _prompt("  Action: ").strip()
        if action == "v":
            print()
            try:
                rc = runner.validate_question(provider, current, progress)
                results[current.id] = "PASS" if rc == 0 else "FAIL"
            except Exception as exc:  # noqa: BLE001 - keep the exam alive; it can still be ended/scored
                print(ui.c("91", f"  Validation could not run: {exc}"))
                results[current.id] = "FAIL"
            print()
            _prompt("  Press Enter")
        elif action == "s":
            provider.interactive_shell(_select_ssh_machine(current))
        elif action == "t":
            print()
            print(runner.format_task_text(current))
            _prompt("  Press Enter")
        elif action == "b":
            return


def _finish_exam(selected, results, started, end_reason, args):
    ended = time.time()
    passed = sum(1 for r in results.values() if r == "PASS")
    total = len(selected)
    pct = round(passed / total * 100, 2) if total else 0
    pass_bool = pct >= args.threshold
    session = {
        "session_id": _new_id(),
        "started_ts": datetime.fromtimestamp(started, timezone.utc).isoformat(),
        "ended_ts": datetime.fromtimestamp(ended, timezone.utc).isoformat(),
        "duration_used_sec": int(round(ended - started)),
        "question_ids": [q.id for q in selected],
        "per_question": [
            {"qid": q.id, "domain": q.domain, "distro": q.distro or "ubuntu",
             "result": results[q.id]} for q in selected
        ],
        "score": passed, "total": total, "percentage": pct,
        "pass_bool": pass_bool, "threshold_used": args.threshold,
        "end_reason": end_reason,
    }
    ExamSessions(LAB_ROOT / "data" / "exam-sessions.json").append(session)
    _write_score_report(session, args)
    return session


def _write_score_report(session, args):
    badge = ui.c("1;92", "  PASS  ") if session["pass_bool"] else ui.c("1;91", "  FAIL  ")
    pct_color = "1;92" if session["percentage"] >= args.threshold else "1;91"
    n_fail = sum(1 for p in session["per_question"] if p["result"] == "FAIL")
    ui.section_header("Exam Score Report")
    print()
    print(f"  Result   {badge}  {ui.c(pct_color, str(session['percentage']) + '%')}  "
          f"{ui.c('97', str(session['score']) + '/' + str(session['total']))} correct  "
          f"{n_fail} failed")
    print("  " + ui.c("90", f"Threshold : approx. {session['threshold_used']}% (not an official LFCS figure)"))
    print("  " + ui.c("90", f"Time used : {session['duration_used_sec']}s  |  End: {session['end_reason']}"))
    print()
    for p in session["per_question"]:
        rb = ui.exam_result_badge(p["result"])
        print(f"  {rb}  {ui.c('97', p['qid'])}  {ui.c('36', p['domain'])}  {ui.c('90', p['distro'])}")
    print()


def _new_id() -> str:
    import uuid
    return str(uuid.uuid4())


# ---- entry -------------------------------------------------------------------

def _check_provider_or_warn(provider) -> bool:
    if provider.available():
        return True
    print(ui.c("93",
               "  Note: vagrant and/or VirtualBox were not found on PATH.\n"
               "  You can browse questions, but loading/validating needs the VMs.\n"
               "  Install VirtualBox + Vagrant, then run: vagrant up"))
    return False


def run_gate(provider, questions, qid) -> int:
    """End-to-end self-test of one question (mirrors run_question_gate.ps1):
    load -> validate-must-fail -> solve -> validate-must-pass -> restore.
    Prints '<qid> PASS/PASS/PASS/PASS' and returns 0 only if every stage passes."""
    q = next((x for x in questions if x.id == qid), None)
    if q is None:
        print(ui.c("91", f"  Unknown question id: {qid}"))
        return 2
    load = unsolved = solved = restored = "FAIL"
    try:
        if not runner.load_question(provider, LAB_ROOT, q):
            raise RuntimeError("load failed")
        load = "PASS"

        rc = runner.validate_question(provider, q, None)
        if rc != 0:
            unsolved = "PASS"  # correct: an unsolved question must fail validation
        else:
            raise RuntimeError("unsolved validate unexpectedly passed")

        runner.invoke_solution(provider, LAB_ROOT, q)
        rc = runner.validate_question(provider, q, None)
        if rc == 0:
            solved = "PASS"
        else:
            raise RuntimeError("solved validate did not pass")

        for m in q.machines():
            provider.restore_base(m)
        restored = "PASS"
    except Exception as exc:  # noqa: BLE001
        print(ui.c("91", f"  gate error: {exc}"))
    result = f"{qid} {load}/{unsolved}/{solved}/{restored}"
    ok = (load == "PASS" and unsolved == "PASS" and solved == "PASS" and restored == "PASS")
    print(ui.c("1;92", result) if ok else ui.c("1;91", result))
    return 0 if ok else 1


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description="LFCS Exam Lab launcher")
    parser.add_argument("--mode", choices=["menu", "practice", "exam"], default="menu")
    parser.add_argument("--provider", default="vagrant")
    parser.add_argument("--exam-duration", type=int, default=120)
    parser.add_argument("--exam-count", type=int, default=20)
    parser.add_argument("--threshold", type=int, default=66)
    parser.add_argument("--seed", type=int, default=0)
    parser.add_argument("--use-seed", action="store_true")
    parser.add_argument("--list", action="store_true",
                        help="print the practice list and exit (no VMs needed)")
    parser.add_argument("--gate", metavar="QID",
                        help="self-test one question end-to-end (load->fail->solve->pass->restore); "
                             "exits 0 only if all stages pass. Used by install.sh to self-verify.")
    args = parser.parse_args(argv)

    questions = load_questions(LAB_ROOT)
    progress = Progress(LAB_ROOT / "progress.json")

    if args.list:
        _show_question_menu(questions, progress)
        return 0

    provider = get_provider(args.provider, LAB_ROOT)

    if args.gate:
        return run_gate(provider, questions, args.gate)

    if args.mode == "practice":
        _check_provider_or_warn(provider)
        start_practice(provider, questions, progress)
        return 0
    if args.mode == "exam":
        _check_provider_or_warn(provider)
        start_exam(provider, questions, progress, args)
        return 0

    ui.clear_screen()
    print()
    print(ui.c("1;96", "  +--------------------------------------+"))
    print(ui.c("1;96", "  |           LFCS Exam Lab               |"))
    print(ui.c("1;96", "  +--------------------------------------+"))
    print()
    print(f"  {ui.c('1;97', '[1]')}  {ui.c('97', 'Practice Mode')}  "
          f"{ui.c('90', '| free navigation | no timer | hints available')}")
    print(f"  {ui.c('1;97', '[2]')}  {ui.c('97', 'Exam Mode')}      "
          f"{ui.c('90', f'| timed {args.exam_duration}min | {args.exam_count} random questions | scored')}")
    print()
    choice = _prompt("  Select mode: ").strip()
    if choice == "1":
        _check_provider_or_warn(provider)
        start_practice(provider, questions, progress)
    elif choice == "2":
        _check_provider_or_warn(provider)
        start_exam(provider, questions, progress, args)
    else:
        print(ui.c("91", "  Invalid choice"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
