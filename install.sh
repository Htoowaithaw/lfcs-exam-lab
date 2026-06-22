#!/usr/bin/env bash
# Smart installer / preflight for the LFCS Exam Lab (macOS / Linux).
#
# One command on a bare machine:
#   1. checks the host can run the lab (OS/arch, CPU virtualization, RAM, disk)
#   2. detects conflicting virtualization (KVM in use; Apple Silicon = hard stop)
#   3. detects / installs Vagrant + VirtualBox + python3
#   4. builds the VMs (vagrant up + base snapshots) only if missing
#   5. self-verifies by running:  python3 lab.py --gate q005
# Then practice with:  ./lfcs.sh
#
# Usage:
#   ./install.sh --check-only     # safe: readiness report only, changes nothing
#   ./install.sh                  # full guided install
#   ./install.sh --yes            # assume yes for normal prompts (not destructive ones)
#
# NOTE: ASCII-only on purpose (portable across terminals). Targets bash 3.2+
# (macOS ships 3.2), so no associative arrays / mapfile.

set -u

CHECK_ONLY=0
ASSUME_YES=0
REBUILD=0
SKIP_BUILD=0
SKIP_SMOKE=0
for arg in "$@"; do
  case "$arg" in
    --check-only) CHECK_ONLY=1 ;;
    --yes|-y)     ASSUME_YES=1 ;;
    --rebuild)    REBUILD=1 ;;
    --skip-build) SKIP_BUILD=1 ;;
    --skip-smoke) SKIP_SMOKE=1 ;;
    -h|--help)    grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $arg"; exit 2 ;;
  esac
done

LAB_ROOT="$(cd "$(dirname "$0")" && pwd)"

# ---- requirements (from the Vagrantfile resource asks) ----------------------
MIN_RAM_GB=8;  REC_RAM_GB=16
MIN_DISK_GB=30; REC_DISK_GB=50
MIN_CPU=2;     REC_CPU=4

# ---- colors (ANSI; disabled when not a TTY or NO_COLOR set) -----------------
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  C_CYAN=$'\033[1;36m'; C_GREEN=$'\033[32m'; C_YEL=$'\033[33m'; C_RED=$'\033[31m'
  C_GRAY=$'\033[90m'; C_OFF=$'\033[0m'
else
  C_CYAN=; C_GREEN=; C_YEL=; C_RED=; C_GRAY=; C_OFF=
fi

PROBLEMS=0; WARNINGS=0
head()  { printf '\n%s== %s ==%s\n' "$C_CYAN" "$1" "$C_OFF"; }
ok()    { printf '  %s[ OK ]%s %s\n' "$C_GREEN" "$C_OFF" "$1"; }
warn()  { printf '  %s[WARN]%s %s\n' "$C_YEL" "$C_OFF" "$1"; WARNINGS=$((WARNINGS+1)); }
bad()   { printf '  %s[FAIL]%s %s\n' "$C_RED" "$C_OFF" "$1"; PROBLEMS=$((PROBLEMS+1)); }
info()  { printf '  %s%s%s\n' "$C_GRAY" "$1" "$C_OFF"; }

ask_yesno() {  # $1=question  $2=default(yes|no)
  local q="$1" def="${2:-yes}" ans
  if [ "$ASSUME_YES" = "1" ] && [ "$def" != "no" ]; then return 0; fi
  if [ "$def" = "no" ]; then printf '  %s [y/N] ' "$q"; else printf '  %s [Y/n] ' "$q"; fi
  read -r ans || true
  if [ -z "$ans" ]; then [ "$def" = "no" ] && return 1 || return 0; fi
  case "$ans" in y|Y|yes|YES) return 0 ;; *) return 1 ;; esac
}

have() { command -v "$1" >/dev/null 2>&1; }

# ---- detection --------------------------------------------------------------
OS="$(uname -s)"; ARCH="$(uname -m)"
PKG=""   # apt | dnf | brew | ""
VBOXMANAGE=""

find_vboxmanage() {
  if have VBoxManage; then VBOXMANAGE="$(command -v VBoxManage)"; return; fi
  for p in /usr/bin/VBoxManage /usr/local/bin/VBoxManage \
           "/Applications/VirtualBox.app/Contents/MacOS/VBoxManage"; do
    [ -x "$p" ] && { VBOXMANAGE="$p"; return; }
  done
  VBOXMANAGE=""
}

detect_pkg() {
  if [ "$OS" = "Darwin" ]; then
    have brew && PKG="brew" || PKG=""
  else
    if have apt-get; then PKG="apt"; elif have dnf; then PKG="dnf"; else PKG=""; fi
  fi
}

preflight() {
  head "System"
  info "OS   : $OS"
  info "Arch : $ARCH"
  if [ "$OS" = "Darwin" ] && { [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; }; then
    bad "Apple Silicon (arm64): VirtualBox cannot run the x86 Ubuntu/Rocky VMs this lab uses."
    info "There is no VirtualBox path on Apple Silicon. A cloud/Codespaces option would be needed (not this installer)."
  elif [ "$ARCH" != "x86_64" ] && [ "$ARCH" != "amd64" ]; then
    bad "CPU arch '$ARCH' is not x86-64; VirtualBox needs x86-64."
  else
    ok "x86-64 architecture"
  fi

  head "CPU"
  local cores=1
  if [ "$OS" = "Darwin" ]; then cores="$(sysctl -n hw.ncpu 2>/dev/null || echo 1)"
  else cores="$(nproc 2>/dev/null || echo 1)"; fi
  info "Logical processors: $cores"
  if [ "$cores" -ge "$REC_CPU" ]; then ok "$cores logical processors (>= $REC_CPU recommended)"
  elif [ "$cores" -ge "$MIN_CPU" ]; then warn "$cores logical processors (>= $MIN_CPU min; $REC_CPU recommended)"
  else bad "$cores logical processors (need >= $MIN_CPU)"; fi

  # virtualization support
  if [ "$OS" = "Linux" ]; then
    if grep -Eq '(vmx|svm)' /proc/cpuinfo 2>/dev/null; then ok "Hardware virtualization (VT-x/AMD-V) present"
    else bad "No VT-x/AMD-V flag in /proc/cpuinfo - enable virtualization in BIOS, or VMs cannot start"; fi
  fi

  head "Conflicting virtualization"
  if [ "$OS" = "Linux" ]; then
    if lsmod 2>/dev/null | grep -q '^kvm'; then
      warn "KVM kernel modules are loaded. If a KVM/QEMU guest is running, it can hold VT-x and block VirtualBox."
      info "VirtualBox usually works when no KVM guest is active; stop KVM guests if VMs fail to start."
    else
      ok "No KVM conflict detected"
    fi
  else
    ok "No conflicting hypervisor check needed on macOS (Intel)"
  fi

  head "Memory"
  local total_gb=0
  if [ "$OS" = "Darwin" ]; then
    total_gb="$(echo "$(sysctl -n hw.memsize 2>/dev/null || echo 0)/1073741824" | bc 2>/dev/null || echo 0)"
  else
    local kb; kb="$(awk '/MemTotal/{print $2}' /proc/meminfo 2>/dev/null || echo 0)"
    total_gb="$(( kb / 1048576 ))"
  fi
  info "Total RAM: ${total_gb} GB"
  if [ "${total_gb%.*}" -ge "$REC_RAM_GB" ] 2>/dev/null; then ok "${total_gb} GB RAM (>= $REC_RAM_GB recommended)"
  elif [ "${total_gb%.*}" -ge "$MIN_RAM_GB" ] 2>/dev/null; then warn "${total_gb} GB RAM (>= $MIN_RAM_GB min; $REC_RAM_GB recommended)"
  else bad "${total_gb} GB RAM (need >= $MIN_RAM_GB; node1+node2 alone want ~7 GB)"; fi

  head "Disk"
  local free_gb; free_gb="$(df -Pk "$LAB_ROOT" | awk 'NR==2{print int($4/1048576)}')"
  info "Free on lab volume: ${free_gb} GB"
  if [ "$free_gb" -ge "$REC_DISK_GB" ]; then ok "${free_gb} GB free (>= $REC_DISK_GB recommended)"
  elif [ "$free_gb" -ge "$MIN_DISK_GB" ]; then warn "${free_gb} GB free (>= $MIN_DISK_GB min; $REC_DISK_GB recommended)"
  else bad "${free_gb} GB free (need >= $MIN_DISK_GB for boxes + VM disks + scratch disks)"; fi

  head "Lab tooling"
  detect_pkg
  if [ -n "$PKG" ]; then ok "Package manager: $PKG"; else warn "No supported package manager (brew/apt/dnf) found - you'd install tools manually"; fi
  have vagrant && ok "Vagrant present: $(vagrant --version 2>/dev/null)" || warn "Vagrant not found (installer can add it)"
  find_vboxmanage
  [ -n "$VBOXMANAGE" ] && ok "VirtualBox present: $("$VBOXMANAGE" --version 2>/dev/null)" || warn "VirtualBox not found (installer can add it)"
  have python3 && ok "python3 present: $(python3 --version 2>/dev/null)" || warn "python3 not found (needed by the launcher; installer can add it)"

  if have vagrant && [ -n "$VBOXMANAGE" ]; then
    head "Images & build state"
    local boxes; boxes="$(vagrant box list 2>/dev/null || true)"
    for b in "bento/ubuntu-22.04" "bento/rockylinux-9"; do
      echo "$boxes" | grep -q "$b" && ok "box present: $b" || info "box not downloaded yet: $b (vagrant up fetches it)"
    done
    for vm in lfcs-node1 lfcs-node2 lfcs-rocky1; do
      if "$VBOXMANAGE" snapshot "$vm" list --machinereadable 2>/dev/null | grep -q 'SnapshotName="base"'; then
        ok "$vm : base snapshot present (built)"
      else
        info "$vm : not built yet"
      fi
    done
  fi
}

verdict() {
  head "Readiness"
  if [ "$PROBLEMS" -gt 0 ]; then
    printf '  %sBLOCKED: %d problem(s), %d warning(s). Fix the [FAIL] items, then re-run.%s\n' "$C_RED" "$PROBLEMS" "$WARNINGS" "$C_OFF"
    return 2
  fi
  if [ "$WARNINGS" -gt 0 ]; then
    printf '  %sREADY WITH WARNINGS: %d warning(s) - review [WARN] items above.%s\n' "$C_YEL" "$WARNINGS" "$C_OFF"
    return 1
  fi
  printf '  %sREADY: this machine can build and run the lab.%s\n' "$C_GREEN" "$C_OFF"
  return 0
}

# ---- actions ----------------------------------------------------------------
need_sudo() { [ "$(id -u)" -ne 0 ] && echo "sudo" || echo ""; }

install_tools() {
  local sudo; sudo="$(need_sudo)"
  if ! have vagrant || [ -z "$VBOXMANAGE" ] || ! have python3; then
    head "Install missing tools"
    case "$PKG" in
      brew)
        ask_yesno "Install missing tools via Homebrew?" && {
          have vagrant   || brew install --cask vagrant
          [ -n "$VBOXMANAGE" ] || brew install --cask virtualbox
          have python3   || brew install python
        } ;;
      apt)
        ask_yesno "Install missing tools via apt (needs sudo)?" && {
          $sudo apt-get update
          $sudo apt-get install -y virtualbox vagrant python3
        } ;;
      dnf)
        ask_yesno "Install missing tools via dnf (needs sudo)?" && {
          $sudo dnf install -y @virtualization VirtualBox vagrant python3 || \
          $sudo dnf install -y VirtualBox vagrant python3
        } ;;
      *)
        bad "No package manager available. Install VirtualBox + Vagrant + python3 manually, then re-run."
        return 1 ;;
    esac
    find_vboxmanage
    if ! have vagrant || [ -z "$VBOXMANAGE" ] || ! have python3; then
      warn "Some tools still missing after install. Check the messages above and re-run."
      return 1
    fi
    ok "Tools present."
  fi
  return 0
}

build_vms() {
  head "Build VMs"
  info "First build downloads ~1.5 GB of images and provisions 3 VMs."
  info "Expect roughly 20-45 minutes depending on network and disk speed."
  ask_yesno "Start the build now?" || { warn "Build skipped."; return 1; }
  cd "$LAB_ROOT" || return 1
  for m in node1 node2 lfcs-rocky1; do
    local vbox="$m"; [ "$m" = "node1" ] && vbox="lfcs-node1"; [ "$m" = "node2" ] && vbox="lfcs-node2"
    if [ "$REBUILD" = "0" ] && "$VBOXMANAGE" snapshot "$vbox" list --machinereadable 2>/dev/null | grep -q 'SnapshotName="base"'; then
      info "$m: base snapshot exists; skipping."
      continue
    fi
    info "$m: vagrant up --provision ..."
    vagrant up "$m" --provision || { bad "vagrant up failed for $m"; return 1; }
    info "$m: saving base snapshot ..."
    vagrant snapshot save "$m" base || { bad "snapshot save failed for $m"; return 1; }
  done
  ok "Build complete; base snapshots saved."
  return 0
}

smoke_test() {
  head "Self-verify (smoke test)"
  info "Runs q005 end-to-end: load -> validate-fails -> solve -> validate-passes -> restore."
  ask_yesno "Run the self-verify now? (boots a VM briefly)" || { warn "Smoke test skipped - install unverified."; return 2; }
  cd "$LAB_ROOT" || return 1
  if python3 lab.py --gate q005; then
    ok "VERIFIED: q005 passed end-to-end on this machine."
    return 0
  fi
  bad "Self-verify FAILED. Lab is installed but a question did not pass end-to-end."
  return 1
}

# ---- main -------------------------------------------------------------------
printf '\n%sLFCS Exam Lab - smart installer (macOS/Linux)%s\n' "$C_CYAN" "$C_OFF"
echo "Lab root: $LAB_ROOT"
preflight
verdict; V=$?

if [ "$CHECK_ONLY" = "1" ]; then
  printf '\n%sCheck-only mode: nothing was changed. Re-run without --check-only to install/build.%s\n' "$C_GRAY" "$C_OFF"
  exit $V
fi
if [ "$V" -eq 2 ]; then
  printf '\n%sResolve the [FAIL] items above, then re-run ./install.sh%s\n' "$C_RED" "$C_OFF"
  exit 2
fi

install_tools || exit 1

if [ "$SKIP_BUILD" = "1" ]; then
  info "SkipBuild set - not building."
else
  build_vms || true
fi

SMOKE_RC=2
if [ "$SKIP_SMOKE" = "0" ] && [ "$SKIP_BUILD" = "0" ]; then
  smoke_test; SMOKE_RC=$?
fi

head "Done"
if [ "$SMOKE_RC" = "0" ]; then
  printf '  %sSetup verified. Start practicing:%s\n' "$C_GREEN" "$C_OFF"
else
  printf '  %sSetup complete. Start practicing:%s\n' "$C_GREEN" "$C_OFF"
fi
echo "    ./lfcs.sh"
exit 0
