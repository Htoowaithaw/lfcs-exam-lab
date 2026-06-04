#!/usr/bin/env bash
set -euo pipefail
grep -q '^allow 192.168.56.11' /etc/chrony/chrony.conf || echo 'allow 192.168.56.11' >> /etc/chrony/chrony.conf
grep -q '^local stratum 10' /etc/chrony/chrony.conf || echo 'local stratum 10' >> /etc/chrony/chrony.conf
systemctl enable --now chrony
systemctl restart chrony
