#!/usr/bin/env bash
set -euo pipefail
setenforce 1
setsebool -P nis_enabled on
