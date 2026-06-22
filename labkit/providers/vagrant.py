"""Vagrant + VirtualBox provider — full 250-question fidelity.

A faithful, cross-platform port of the VM logic in lab.ps1: SSH access via
`vagrant ssh-config`, state/reset via `VBoxManage` snapshots, and NAT SSH port
forwarding re-applied after each snapshot restore (restoring a snapshot drops
the runtime forwarding rule). Works anywhere VirtualBox + Vagrant run
(Linux, Intel macOS, Windows).
"""

from __future__ import annotations

import os
import shutil
import subprocess
import time
from pathlib import Path
from typing import Dict, List

from labkit.providers.base import Provider, RunResult

_VBOX_NAME = {
    "node1": "lfcs-node1",
    "node2": "lfcs-node2",
    "lfcs-rocky1": "lfcs-rocky1",
}

# Private-network peer IPs for the two-node questions (from the Vagrantfile).
_PEER = {"node1": "192.168.56.12", "node2": "192.168.56.11"}


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

    def _vbox(self, *args: str) -> subprocess.CompletedProcess:
        return subprocess.run(
            [self.vboxmanage, *args],
            capture_output=True, text=True, cwd=str(self.lab_root),
        )

    def _vbox_checked(self, *args: str) -> List[str]:
        cp = self._vbox(*args)
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
            capture_output=True, text=True, cwd=str(self.lab_root),
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
                    info[key] = s[len(key):].strip().strip('"')
        if not (info["HostName"] and info["Port"] and info["IdentityFile"]):
            raise RuntimeError(f"Incomplete SSH config for {machine}")
        self._ssh_cache[machine] = info
        return info

    def _ssh_base_args(self, info: Dict[str, str], interactive: bool) -> List[str]:
        args = ["ssh"]
        if interactive:
            args.append("-t")
        args += [
            "-o", "StrictHostKeyChecking=no",
            "-o", f"UserKnownHostsFile={os.devnull}",
            "-o", "PasswordAuthentication=no",
            "-o", "IdentitiesOnly=yes",
            "-i", info["IdentityFile"],
            "-p", info["Port"],
        ]
        if not interactive:
            args += [
                "-o", "LogLevel=ERROR",
                "-o", "ConnectTimeout=5",
                "-o", "ConnectionAttempts=1",
                "-o", "BatchMode=yes",
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
        print("  " + ui.c("1;96", f"Opening SSH -> {machine}")
              + "  " + ui.c("90", "| type 'exit' to return, then press [v] to validate"))
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
        has_rule = any(l.startswith('Forwarding(') and '="ssh,' in l for l in details)
        if has_rule:
            self._vbox("controlvm", name, "natpf1", "delete", "ssh")
        rule = f"ssh,tcp,{info['HostName']},{info['Port']},,22"
        self._vbox_checked("controlvm", name, "natpf1", rule)

    def _wait_ssh(self, machine: str, timeout: int = 90) -> None:
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
