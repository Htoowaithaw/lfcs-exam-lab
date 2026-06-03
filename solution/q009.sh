#!/usr/bin/env bash
set -euo pipefail
groupadd lfcsgrp
useradd -u 2401 -m -s /bin/bash -G lfcsgrp -e 2030-12-31 examuser
