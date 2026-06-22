"""Provider interface shared by every backend."""

from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import List


@dataclass
class RunResult:
    code: int
    output: List[str]


class Provider(ABC):
    """A backend that supplies the lab's Linux machines.

    Implementations drive a concrete environment (VirtualBox VMs via Vagrant
    today). The question workflow in `labkit.runner` calls only these methods,
    so it stays backend-agnostic.
    """

    name: str = "base"

    @abstractmethod
    def available(self) -> bool:
        """True if the backend tooling is installed and usable on this host."""

    @abstractmethod
    def is_running(self, machine: str) -> bool:
        """True if the named machine is currently running."""

    @abstractmethod
    def restore_base(self, machine: str) -> None:
        """Reset the machine to its clean 'base' state and leave it SSH-ready.

        Raises on failure (caller treats that as 'load failed').
        """

    @abstractmethod
    def run(self, machine: str, command: str) -> RunResult:
        """Run a command non-interactively as the lab user; capture output."""

    @abstractmethod
    def interactive_shell(self, machine: str) -> None:
        """Open an interactive shell on the machine for the user to solve in."""

    def wait_peer(self, machines: List[str]) -> None:
        """Optional: block until multi-node peers can reach each other.

        Default no-op; backends with multi-node support override this.
        """
        return None
