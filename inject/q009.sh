#!/usr/bin/env bash
set -euo pipefail
userdel -r examuser >/dev/null 2>&1 || true
groupdel lfcsgrp >/dev/null 2>&1 || true
