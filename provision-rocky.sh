#!/usr/bin/env bash
set -euo pipefail

dnf -y makecache
dnf -y install \
  at \
  acl \
  attr \
  bc \
  bind-utils \
  chrony \
  createrepo_c \
  firewalld \
  git \
  httpd \
  jq \
  lvm2 \
  lsof \
  man-db \
  mdadm \
  nano \
  net-tools \
  nfs-utils \
  openssl \
  policycoreutils \
  policycoreutils-python-utils \
  procps-ng \
  rpm-build \
  rsync \
  setools-console \
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

rm -rf /opt/lfcs-r04-build /opt/lfcs-r04-src /opt/lfcs-r04-repo
mkdir -p /opt/lfcs-r04-build/BUILD /opt/lfcs-r04-build/RPMS /opt/lfcs-r04-build/SOURCES /opt/lfcs-r04-build/SPECS /opt/lfcs-r04-build/SRPMS
mkdir -p /opt/lfcs-r04-src/usr/local/bin
cat >/opt/lfcs-r04-src/usr/local/bin/lfcs-r04-tool <<'EOF'
#!/usr/bin/env bash
echo lfcs-r04-tool
EOF
chmod +x /opt/lfcs-r04-src/usr/local/bin/lfcs-r04-tool
tar -C /opt -czf /opt/lfcs-r04-build/SOURCES/lfcs-r04-tool-1.0.tar.gz lfcs-r04-src
cat >/opt/lfcs-r04-build/SPECS/lfcs-r04-tool.spec <<'EOF'
Name: lfcs-r04-tool
Version: 1.0
Release: 1%{?dist}
Summary: LFCS local repo test tool
License: MIT
BuildArch: noarch
Source0: lfcs-r04-tool-1.0.tar.gz

%description
LFCS local repo test tool.

%prep
%setup -q -n lfcs-r04-src

%build

%install
mkdir -p %{buildroot}/usr/local/bin
install -m 0755 usr/local/bin/lfcs-r04-tool %{buildroot}/usr/local/bin/lfcs-r04-tool

%files
/usr/local/bin/lfcs-r04-tool
EOF
rpmbuild --define '_topdir /opt/lfcs-r04-build' -bb /opt/lfcs-r04-build/SPECS/lfcs-r04-tool.spec >/dev/null
mkdir -p /opt/lfcs-r04-repo
cp /opt/lfcs-r04-build/RPMS/noarch/lfcs-r04-tool-1.0-1*.rpm /opt/lfcs-r04-repo/
createrepo_c /opt/lfcs-r04-repo >/dev/null
dnf clean all >/dev/null

dnf -y repolist >/dev/null
getenforce | grep -q Enforcing
systemctl is-enabled firewalld >/dev/null
systemctl is-active firewalld >/dev/null
