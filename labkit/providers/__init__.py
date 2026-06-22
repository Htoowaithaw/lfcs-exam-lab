"""Environment providers — pluggable backends that supply the Linux machines.

A provider knows how to reset a machine to a clean state, run a command on it,
and open an interactive shell. The question workflow (inject/validate/solution)
lives in `labkit.runner` and is provider-agnostic, so new backends (Multipass or
Docker for the non-storage subset, a cloud provider, etc.) can be added without
touching question logic.
"""

from labkit.providers.base import Provider, RunResult

__all__ = ["Provider", "RunResult", "get_provider"]


def get_provider(name: str, lab_root):
    """Construct a provider by name. Currently only the Vagrant/VirtualBox
    backend (full 250-question fidelity). New backends register here."""
    name = (name or "vagrant").lower()
    if name in ("vagrant", "virtualbox", "vbox"):
        from labkit.providers.vagrant import VagrantVirtualBoxProvider

        return VagrantVirtualBoxProvider(lab_root)
    raise ValueError(f"Unknown provider '{name}'. Available: vagrant")
