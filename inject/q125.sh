#!/usr/bin/env bash
set -euo pipefail
nft delete table inet lfcs4 >/dev/null 2>&1 || true
