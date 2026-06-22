"""Terminal UI helpers: ANSI color, badges, rules, section headers.

ASCII-only source (the Unicode box-art that broke lab.ps1 under Windows
PowerShell taught us that lesson). Colors come from ANSI escape codes, which are
pure ASCII and render on Linux/macOS terminals and modern Windows consoles.

Color auto-disables when stdout is not a TTY (piped/redirected) or when the
NO_COLOR convention is set, so captured output stays clean.
"""

from __future__ import annotations

import os
import sys

# ---- color enablement --------------------------------------------------------

def _supports_color() -> bool:
    if os.environ.get("NO_COLOR") is not None:
        return False
    if os.environ.get("LFCS_NO_COLOR") is not None:
        return False
    if not sys.stdout.isatty():
        return False
    return True


def _enable_windows_vt() -> None:
    """Turn on ANSI processing in legacy Windows consoles (no-op elsewhere)."""
    if os.name != "nt":
        return
    try:
        import ctypes

        kernel32 = ctypes.windll.kernel32
        # -11 = STD_OUTPUT_HANDLE; 0x0004 = ENABLE_VIRTUAL_TERMINAL_PROCESSING
        handle = kernel32.GetStdHandle(-11)
        mode = ctypes.c_uint32()
        if kernel32.GetConsoleMode(handle, ctypes.byref(mode)):
            kernel32.SetConsoleMode(handle, mode.value | 0x0004)
    except Exception:
        pass


_enable_windows_vt()
COLOR = _supports_color()
ESC = "\x1b"


def c(codes: str, text: str) -> str:
    """Wrap text in an ANSI SGR sequence (or return it plain if color is off)."""
    if not COLOR:
        return text
    return f"{ESC}[{codes}m{text}{ESC}[0m"


# ---- semantic helpers --------------------------------------------------------

def rule(width: int = 60) -> str:
    return c("90", "-" * width)


def status_badge(status: str) -> str:
    return {
        "pass": c("1;92", " PASS "),
        "fail": c("1;91", " FAIL "),
        "attempted": c("33", " .... "),
    }.get(status, c("90", "  NEW "))


def diff_badge(diff: str) -> str:
    if not diff:
        return ""
    return {
        "easy": c("32", diff),
        "medium": c("33", diff),
        "hard": c("31", diff),
    }.get(diff.lower(), diff)


def exam_result_badge(result: str) -> str:
    return {
        "PASS": c("1;92", "PASS"),
        "FAIL": c("1;91", "FAIL"),
    }.get(result, c("90", "----"))


def section_header(title: str, sub: str = "") -> None:
    print()
    print(c("1;96", f"  {title}"))
    if sub:
        print(f"  {sub}")
    print(rule())


def clear_screen() -> None:
    if not sys.stdout.isatty():
        return
    # ANSI clear + home; works on every supported terminal once VT is enabled.
    sys.stdout.write(f"{ESC}[2J{ESC}[H")
    sys.stdout.flush()
