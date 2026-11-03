"""Vagrant + VirtualBox provider — full 250-question fidelity.

A faithful, cross-platform port of the VM logic in lab.ps1: SSH access via
`vagrant ssh-config`, state/reset via `VBoxManage` snapshots, and NAT SSH port
forwarding re-applied after each snapshot restore (restoring a snapshot drops
the runtime forwarding rule). Works anywhere VirtualBox + Vagrant run
(Linux, Intel macOS, Windows).

Self-healing from wedged VMs (Apple Silicon)
---------------------------------------------
VirtualBox's Apple Silicon host backend (Hypervisor.framework/NEM) can
occasionally wedge a VM's execution thread - usually right after a snapshot
restore. When that happens *every* `VBoxManage` call targeting that VM hangs
forever (even read-only ones like `showvminfo`), because VBoxSVC has to
synchronize with the wedged VM's session to answer. There is no graceful
VBoxManage command that unsticks it; the only fix is killing the VM's host
process and letting it restart fresh (see README Troubleshooting).

Every `VBoxManage` call below therefore runs under `_VBOX_TIMEOUT`. On a
timeout, `_vbox_checked` assumes the VM is wedged, kills its host process
(`_kill_host_process`), restarts it if needed (`_recover_wedged`), and retries
the original call exactly once. If the retry also fails, the error propagates
normally - this is a transparent retry, not a silent swallow.
"""

from __future__ import annotations

import os
import re
import shutil
import subprocess
import time
from pathlib import Path
from typing import Dict, List, Optional

from labkit.providers.base import Provider, RunResult

_VBOX_NAME = {
    "node1": "lfcs-node1",
    "node2": "lfcs-node2",
    "lfcs-rocky1": "lfcs-rocky1",
}
_MACHINE_BY_VBOX_NAME = {v: k for k, v in _VBOX_NAME.items()}

# Private-network peer IPs for the two-node questions (from the Vagrantfile).
_PEER = {"node1": "192.168.56.12", "node2": "192.168.56.11"}

# VBoxManage calls should return almost instantly when VirtualBox is healthy;
# a wedged VM never returns at all, so this just needs to be "clearly longer
# than any healthy call", not tuned per-command.
_VBOX_TIMEOUT = 25


class VMWedgedError(RuntimeError):
    """A VBoxManage call didn't return within _VBOX_TIMEOUT. Almost always
    means the target VM's execution thread is wedged (see module docstring),
    not that the command itself is merely slow."""


def _find_vboxmanage() -> str:
    override = os.environ.get("LFCS_VBOXMANAGE")
    if override and Path(override).exists():
        return override
    found = shutil.which("VBoxManage") or shutil.which("VBoxManage.exe")
    if found:
        return found
    candidates = [
        r"C:\Program Files\Oracle\VirtualBox\VBoxManage.exe",
        "/Applications/VirtualBox.app/Contents/MacOS/VBoxManage",
        "/usr/bin/VBoxManage",
        "/usr/local/bin/VBoxManage",
    ]
    for c in candidates:
        if Path(c).exists():
            return c
    return "VBoxManage"  # last resort; will surface a clear error when invoked


class VagrantVirtualBoxProvider(Provider):
    name = "vagrant"

    def __init__(self, lab_root: Path):
        self.lab_root = Path(lab_root)
        self.vboxmanage = _find_vboxmanage()
        self._ssh_cache: Dict[str, Dict[str, str]] = {}

    # ---- availability --------------------------------------------------------

    def available(self) -> bool:
        return shutil.which("vagrant") is not None and (
            Path(self.vboxmanage).exists() or shutil.which(self.vboxmanage) is not None
        )

    # ---- VBoxManage helpers --------------------------------------------------

    def _vbox(
        self, *args: str, timeout: int = _VBOX_TIMEOUT
    ) -> subprocess.CompletedProcess:
        try:
            return subprocess.run(
                [self.vboxmanage, *args],
                capture_output=True,
                text=True,
                cwd=str(self.lab_root),
                timeout=timeout,
            )
        except subprocess.TimeoutExpired as exc:
            raise VMWedgedError(
                f"VBoxManage {' '.join(args)} did not respond within {timeout}s "
                "(VM likely wedged - see README Troubleshooting)"
            ) from exc

    def _machine_in_args(self, args) -> Optional[str]:
        for a in args:
            if a in _MACHINE_BY_VBOX_NAME:
                return _MACHINE_BY_VBOX_NAME[a]
        return None

    def _kill_host_process(self, machine: str) -> None:
        """Force-kill the host-level process(es) running `machine`'s VM.
        VirtualBox 7 splits a headless session into two processes (a thin
        `VBoxHeadless` frontend plus the actual `VirtualBoxVM` execution
        process); both are matched here. Best-effort: used only to break a
        wedge, never for routine shutdown."""
        name = _VBOX_NAME[machine]
        pattern = re.compile(
            r"(VBoxHeadless|VirtualBoxVM)(\.app/Contents/MacOS/\1)? --comment "
            + re.escape(name)
            + r" "
        )
        try:
            ps = subprocess.run(
                ["ps", "-eo", "pid,command"], capture_output=True, text=True, timeout=5
            )
        except Exception:  # noqa: BLE001
            return
        for line in ps.stdout.splitlines()[1:]:
            line = line.strip()
            if not line:
                continue
            pid_str, _, cmd = line.partition(" ")
            if pattern.search(cmd):
                try:
                    os.kill(int(pid_str), 9)
                except (ValueError, ProcessLookupError, PermissionError):
                    pass

    def _recover_wedged(self, machine: str) -> None:
        from labkit import ui

        name = _VBOX_NAME[machine]
        print(
            ui.c(
                "93",
                f"  VirtualBox looks wedged on {machine} - killing and restarting it...",
            )
        )
        self._kill_host_process(machine)
        time.sleep(2)
        # Raw, unwrapped calls here (short timeouts, best-effort) - going
        # through _vbox()/_vbox_checked() would recurse into this same
        # recovery path if VBoxSVC itself is still unhappy.
        try:
            cp = subprocess.run(
                [self.vboxmanage, "showvminfo", name, "--machinereadable"],
                capture_output=True,
                text=True,
                timeout=10,
            )
            running = 'VMState="running"' in (cp.stdout or "")
        except Exception:  # noqa: BLE001
            running = False
        if not running:
            try:
                subprocess.run(
                    [self.vboxmanage, "startvm", name, "--type", "headless"],
                    capture_output=True,
                    text=True,
                    timeout=20,
                )
            except Exception:  # noqa: BLE001
                pass
            time.sleep(1)

    def _vbox_checked(self, *args: str) -> List[str]:
        try:
            cp = self._vbox(*args)
        except VMWedgedError as exc:
            machine = self._machine_in_args(args)
            if machine is None:
                raise
            print(f"  {exc}")
            self._recover_wedged(machine)
            cp = self._vbox(*args)  # retry once; a second failure propagates normally
        if cp.returncode != 0:
            detail = (cp.stderr or cp.stdout or "").strip() or f"exit {cp.returncode}"
            raise RuntimeError(f"VBoxManage {' '.join(args)} failed: {detail}")
        return (cp.stdout or "").splitlines()

    def _vm_state(self, machine: str) -> str:
        name = _VBOX_NAME[machine]
        for line in self._vbox_checked("showvminfo", name, "--machinereadable"):
            if line.startswith("VMState="):
                return line.split("=", 1)[1].strip().strip('"')
        raise RuntimeError(f"VBoxManage did not report VMState for {name}")

    def is_running(self, machine: str) -> bool:
        try:
            return self._vm_state(machine) == "running"
        except Exception as exc:  # noqa: BLE001
            print(f"  {exc}")
            return False

    # ---- SSH info ------------------------------------------------------------

    def _ssh_info(self, machine: str) -> Dict[str, str]:
        if machine in self._ssh_cache:
            return self._ssh_cache[machine]
        cp = subprocess.run(
            ["vagrant", "ssh-config", machine],
            capture_output=True,
            text=True,
            cwd=str(self.lab_root),
        )
        if cp.returncode != 0:
            raise RuntimeError(
                f"VM '{machine}' is unavailable or not SSH-ready. "
                f"Run: vagrant up {machine}"
            )
        info = {"HostName": "", "Port": "", "IdentityFile": "", "User": "vagrant"}
        for line in cp.stdout.splitlines():
            s = line.strip()
            for key in ("HostName", "Port", "IdentityFile", "User"):
                if s.startswith(key + " "):
                    info[key] = s[len(key) :].strip().strip('"')
        if not (info["HostName"] and info["Port"] and info["IdentityFile"]):
            raise RuntimeError(f"Incomplete SSH config for {machine}")
        self._ssh_cache[machine] = info
        return info

    def _ssh_base_args(self, info: Dict[str, str], interactive: bool) -> List[str]:
        args = ["ssh"]
        if interactive:
            args.append("-t")
        args += [
            "-o",
            "StrictHostKeyChecking=no",
            "-o",
            f"UserKnownHostsFile={os.devnull}",
            "-o",
            "PasswordAuthentication=no",
            "-o",
            "IdentitiesOnly=yes",
            "-i",
            info["IdentityFile"],
            "-p",
            info["Port"],
        ]
        if not interactive:
            args += [
                "-o",
                "LogLevel=ERROR",
                "-o",
                "ConnectTimeout=5",
                "-o",
                "ConnectionAttempts=1",
                "-o",
                "BatchMode=yes",
            ]
        args.append(f"{info['User']}@{info['HostName']}")
        return args

    # ---- command execution ---------------------------------------------------

    def run(self, machine: str, command: str) -> RunResult:
        info = self._ssh_info(machine)
        args = self._ssh_base_args(info, interactive=False) + [command]
        cp = subprocess.run(args, capture_output=True, text=True)
        out = (cp.stdout or "").splitlines() + (cp.stderr or "").splitlines()
        return RunResult(code=cp.returncode, output=out)

    def interactive_shell(self, machine: str) -> None:
        info = self._ssh_info(machine)
        args = self._ssh_base_args(info, interactive=True)
        from labkit import ui

        print("  " + ui.c("90", "ssh " + " ".join(args[1:])))
        print(
            "  "
            + ui.c("1;96", f"Opening SSH -> {machine}")
            + "  "
            + ui.c("90", "| type 'exit' to return, then press [v] to validate")
        )
        try:
            subprocess.run(args)
        except Exception as exc:  # noqa: BLE001
            print("  " + ui.c("91", f"Could not open SSH: {exc}"))
        print("  " + ui.c("90", f"Task saved at /root/TASK.md on {machine}"))

    # ---- reset ---------------------------------------------------------------

    def _set_ssh_forwarding(self, machine: str) -> None:
        name = _VBOX_NAME[machine]
        info = self._ssh_info(machine)
        details = self._vbox_checked("showvminfo", name, "--machinereadable")
        has_rule = any(l.startswith("Forwarding(") and '="ssh,' in l for l in details)
        if has_rule:
            try:
                self._vbox_checked("controlvm", name, "natpf1", "delete", "ssh")
            except Exception:  # noqa: BLE001 - best-effort cleanup; a stale/missing rule is fine
                pass
        rule = f"ssh,tcp,{info['HostName']},{info['Port']},,22"
        self._vbox_checked("controlvm", name, "natpf1", rule)

    def _wait_ssh(
        self, machine: str, timeout: int = 90, _recovered: bool = False
    ) -> None:
        deadline = time.time() + timeout
        while time.time() < deadline:
            if self._vm_state(machine) != "running":
                raise RuntimeError(
                    f"VM {machine} did not become SSH-ready (boot failed). "
                    f"Run: vagrant up {machine}"
                )
            if self.run(machine, "true").code == 0:
                return
            time.sleep(2)
        if not _recovered:
            # VBoxManage reports the VM as "running" but the guest itself never
            # answers SSH - the same Apple Silicon wedge class as a hung
            # VBoxManage call, just manifesting one layer up (the host-level VM
            # object is alive; the guest inside it never actually runs). One
            # recovery attempt (kill + restart) plus a second, shorter wait.
            self._recover_wedged(machine)
            self._set_ssh_forwarding(machine)
            self._wait_ssh(machine, timeout=60, _recovered=True)
            return
        raise RuntimeError(
            f"VM {machine} did not become SSH-ready. Run: vagrant up {machine}"
        )

    def restore_base(self, machine: str) -> None:
        name = _VBOX_NAME[machine]
        if self._vm_state(machine) == "running":
            self._vbox_checked("controlvm", name, "poweroff")
            deadline = time.time() + 30
            while time.time() < deadline and self._vm_state(machine) == "running":
                time.sleep(0.5)
            if self._vm_state(machine) == "running":
                raise RuntimeError(f"poweroff for {name} did not complete in 30s")
        self._vbox_checked("snapshot", name, "restore", "base")
        self._vbox_checked("startvm", name, "--type", "headless")
        time.sleep(1)
        if self._vm_state(machine) != "running":
            raise RuntimeError(
                f"VM {machine} did not start after restore. Run: vagrant up {machine}"
            )
        self._set_ssh_forwarding(machine)
        self._wait_ssh(machine, 90)

    # ---- multi-node ----------------------------------------------------------

    def wait_peer(self, machines: List[str], timeout: int = 90) -> None:
        if len(machines) < 2:
            return
        for machine in ("node1", "node2"):
            if machine not in machines:
                continue
            peer = _PEER[machine]
            deadline = time.time() + timeout
            ok = False
            while time.time() < deadline:
                probe = self.run(machine, f"timeout 2 bash -c '</dev/tcp/{peer}/22'")
                if probe.code == 0:
                    ok = True
                    break
                time.sleep(2)
            if not ok:
                raise RuntimeError(
                    f"VM {machine} could not reach peer {peer}:22. "
                    f"Run: vagrant up {machine}"
                )
