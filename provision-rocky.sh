#!/usr/bin/env bash
set -euo pipefail

dnf -y makecache
dnf -y install \
  at \
  bc \
  bind-utils \
  curl \
  firewalld \
  httpd \
  jq \
  lsof \
  man-db \
  nano \
  net-tools \
  policycoreutils \
  policycoreutils-python-utils \
  procps-ng \
  rsync \
  tar \
  tree \
  vim

systemctl enable --now firewalld

if command -v setenforce >/dev/null 2>&1; then
  setenforce 1 || true
fi
if [ -f /etc/selinux/config ]; then
  sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
fi

mkdir -p /opt/lfcs-lab /srv/lfcs
echo "lfcs rocky base provisioned" > /opt/lfcs-lab/base-rocky.txt

dnf -y repolist >/dev/null
getenforce | grep -q Enforcing
systemctl is-enabled firewalld >/dev/null
systemctl is-active firewalld >/dev/null
