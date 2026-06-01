#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y \
  acl \
  bash-completion \
  bc \
  cron \
  curl \
  e2fsprogs \
  file \
  findutils \
  gzip \
  iproute2 \
  jq \
  less \
  lsof \
  man-db \
  nano \
  net-tools \
  passwd \
  procps \
  psmisc \
  rsync \
  sudo \
  tar \
  tree \
  util-linux \
  vim

systemctl enable --now cron

mkdir -p /opt/lfcs-lab /srv/lfcs
echo "lfcs base provisioned" > /opt/lfcs-lab/base.txt
