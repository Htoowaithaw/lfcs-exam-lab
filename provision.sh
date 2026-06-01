#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y \
  acl \
  apache2 \
  attr \
  bash-completion \
  bc \
  build-essential \
  chrony \
  cron \
  curl \
  docker.io \
  e2fsprogs \
  file \
  findutils \
  git \
  gzip \
  iproute2 \
  jq \
  less \
  lvm2 \
  lsof \
  man-db \
  mdadm \
  nano \
  net-tools \
  nfs-common \
  nfs-kernel-server \
  nginx \
  openssl \
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
