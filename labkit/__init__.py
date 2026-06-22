"""labkit — cross-platform core for the LFCS Exam Lab.

This package backs the portable `lab.py` launcher (Linux/macOS/Windows). It is a
faithful port of the proven `lab.ps1` logic, kept dependency-free (stdlib only)
so users can `git clone` and run with no `pip install` step.

The existing PowerShell launcher (`lab.ps1`) is unchanged and remains the
Windows entry point; `lab.py` is additive.
"""

__all__ = ["questions", "ui"]
