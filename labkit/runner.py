"""Provider-agnostic question workflow: load, validate, solve.

Ports Load-Question / Validate-Question / Invoke-Solution / Install-TaskText and
the multi-VM readiness waits from lab.ps1. Talks only to a Provider, so the same
workflow runs on any backend.
"""

from __future__ import annotations

import base64
from pathlib import Path
from typing import List

from labkit import ui
from labkit.providers.base import Provider
from labkit.questions import Question


def format_task_text(q: Question) -> str:
    body = q.question.replace("\r\n", "\n").replace("\r", "")
    return f"# {q.id}: {q.title}\n\n{body}".rstrip() + "\n"


def _solution_machines(q: Question) -> List[str]:
    """Order machines for applying the reference solution (mirrors
    Get-SolutionMachines): single-node trivially; for two-node SSH questions
    keep node order, otherwise reverse so the server is configured first."""
    machines = q.machines()
    if len(machines) <= 1:
        return machines
    if q.topic == "SSH server & client":
        return machines
    return list(reversed(machines))


def _install_task_text(provider: Provider, q: Question, machine: str) -> None:
    text = format_task_text(q)
    encoded = base64.b64encode(text.encode("utf-8")).decode("ascii")
    cmd = (
        f"printf '%s' '{encoded}' | base64 -d | sudo tee /root/TASK.md >/dev/null "
        f"&& sudo cp /root/TASK.md /etc/motd && sudo chmod 0644 /root/TASK.md /etc/motd"
    )
    res = provider.run(machine, cmd)
    for line in res.output:
        print(line)
    if res.code != 0:
        raise RuntimeError(f"Task publish failed for {q.id} on {machine}")


def load_question(provider: Provider, lab_root: Path, q: Question) -> bool:
    machines = q.machines()
    try:
        # Rocky VM is not snapshot-restored by the lab; require it already up.
        for target in machines:
            if target == "lfcs-rocky1" and not provider.is_running(target):
                raise RuntimeError(
                    "VM 'lfcs-rocky1' is unavailable. Run: vagrant up lfcs-rocky1"
                )
        for target in machines:
            print(ui.c("90", f"  Restoring {target} base snapshot..."))
            provider.restore_base(target)
        provider.wait_peer(machines)
        for target in machines:
            machine_script = Path(lab_root) / f"inject/{q.id}.{target}.sh"
            default_script = Path(lab_root) / f"inject/{q.id}.sh"
            if machine_script.exists():
                print(ui.c("90", f"  Injecting {q.id} on {target}..."))
                res = provider.run(target, f"sudo bash /vagrant/inject/{q.id}.{target}.sh")
                for line in res.output:
                    print(line)
                if res.code != 0:
                    raise RuntimeError(f"Inject failed for {q.id} on {target}")
            elif len(machines) == 1 and default_script.exists():
                print(ui.c("90", f"  Injecting {q.id}..."))
                res = provider.run(target, f"sudo bash /vagrant/inject/{q.id}.sh")
                for line in res.output:
                    print(line)
                if res.code != 0:
                    raise RuntimeError(f"Inject failed for {q.id} on {target}")
        for target in machines:
            _install_task_text(provider, q, target)
        return True
    except Exception as exc:  # noqa: BLE001
        print(ui.c("91", f"  {exc}"))
        return False


def _readiness_commands(q: Question) -> List[str]:
    """Service-up probes for two-node questions (mirrors
    Get-ServiceReadinessCommands). Avoids validating before the peer service
    finished coming up."""
    try:
        n = int(q.id[1:])
    except ValueError:
        return []
    topic = q.topic
    if topic == "NFS":
        return ["timeout 2 bash -c '</dev/tcp/192.168.56.12/2049'"]
    if topic == "NBD":
        return ["timeout 2 bash -c '</dev/tcp/192.168.56.12/10809'"]
    if topic == "reverse proxy & load balancer":
        k = n - 214
        backend, listen = 18700 + k, 18800 + k
        return [
            f"timeout 2 bash -c '</dev/tcp/192.168.56.12/{backend}'",
            f"timeout 2 bash -c '</dev/tcp/127.0.0.1/{listen}'",
        ]
    if topic == "port redirection & NAT":
        port = 18600 + (n - 208)
        return [f"timeout 2 bash -c '</dev/tcp/192.168.56.12/{port}'"]
    if topic == "NTP time sync":
        return ["chronyc sources -n | grep -q '192.168.56.12'"]
    if topic == "SSH server & client":
        return ["timeout 2 bash -c '</dev/tcp/192.168.56.12/22'"]
    if topic == "LDAP accounts":
        return ["timeout 2 bash -c '</dev/tcp/192.168.56.12/389'"]
    return []


def _wait_service_readiness(provider: Provider, q: Question, primary: str) -> None:
    import time

    for command in _readiness_commands(q):
        deadline = time.time() + 60
        ready = False
        while time.time() < deadline:
            if provider.run(primary, command).code == 0:
                ready = True
                break
            time.sleep(2)
        if not ready:
            raise RuntimeError(f"Readiness wait failed on {primary}: {command}")


def validate_question(provider: Provider, q: Question, progress) -> int:
    target = q.target_machine()
    if len(q.machines()) > 1:
        _wait_service_readiness(provider, q, target)
    res = provider.run(target, f"sudo bash /vagrant/validate/{q.id}.sh")
    for line in res.output:
        if line.startswith("RESULT: PASS"):
            print(ui.c("1;92", line))
        elif line.startswith("RESULT: FAIL"):
            print(ui.c("1;91", line))
        else:
            print(line)
    status = "pass" if res.code == 0 else "fail"
    if progress is not None:
        progress.update(q.id, status, True)
    return res.code


def invoke_solution(provider: Provider, lab_root: Path, q: Question) -> None:
    machines = q.machines()
    targets = machines if len(machines) <= 1 else _solution_machines(q)
    for target in targets:
        machine_script = Path(lab_root) / f"solution/{q.id}.{target}.sh"
        default_script = Path(lab_root) / f"solution/{q.id}.sh"
        if machine_script.exists():
            res = provider.run(target, f"sudo bash /vagrant/solution/{q.id}.{target}.sh")
            for line in res.output:
                print(line)
            if res.code != 0:
                raise RuntimeError(f"Solution failed for {q.id} on {target}")
        elif len(machines) == 1 and default_script.exists():
            res = provider.run(target, f"sudo bash /vagrant/solution/{q.id}.sh")
            for line in res.output:
                print(line)
            if res.code != 0:
                raise RuntimeError(f"Solution failed for {q.id} on {target}")
