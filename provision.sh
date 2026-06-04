#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

debconf-set-selections <<'EOF'
slapd slapd/no_configuration boolean false
slapd slapd/domain string lfcs.lab
slapd shared/organization string LFCS Lab
slapd slapd/password1 password admin
slapd slapd/password2 password admin
slapd slapd/backend select MDB
slapd slapd/purge_database boolean true
slapd slapd/move_old_database boolean true
libnss-ldapd libnss-ldapd/nsswitch multiselect passwd, group
nslcd nslcd/ldap-uris string ldap://192.168.56.12/
nslcd nslcd/ldap-base string dc=lfcs,dc=lab
EOF

apt-get update
apt-get install -y \
  acl \
  apache2 \
  attr \
  bash-completion \
  bc \
  build-essential \
  busybox-static \
  chrony \
  cron \
  curl \
  docker.io \
  e2fsprogs \
  file \
  findutils \
  git \
  gzip \
  haproxy \
  iproute2 \
  iptables \
  jq \
  ldap-utils \
  libnss-ldapd \
  libvirt-clients \
  libvirt-daemon-system \
  less \
  lvm2 \
  lsof \
  man-db \
  mdadm \
  nano \
  net-tools \
  nbd-client \
  nbd-server \
  nfs-common \
  nfs-kernel-server \
  nginx \
  nslcd \
  openssl \
  passwd \
  procps \
  psmisc \
  rsync \
  slapd \
  sudo \
  tar \
  tree \
  util-linux \
  vim

systemctl enable --now cron
systemctl enable chrony >/dev/null 2>&1 || true

mkdir -p /opt/lfcs-lab /srv/lfcs
echo "lfcs base provisioned" > /opt/lfcs-lab/base.txt

mkdir -p /opt/lfcs-apt-build/DEBIAN /opt/lfcs-apt-build/usr/local/bin /opt/lfcs-apt-repo
cat >/opt/lfcs-apt-build/DEBIAN/control <<'EOF'
Package: lfcs-apt-tool
Version: 1.0
Section: admin
Priority: optional
Architecture: all
Maintainer: LFCS Lab <lfcs@example.com>
Description: LFCS local apt repository test tool
EOF
cat >/opt/lfcs-apt-build/usr/local/bin/lfcs-apt-tool <<'EOF'
#!/usr/bin/env bash
echo lfcs-apt-tool
EOF
chmod 0755 /opt/lfcs-apt-build/usr/local/bin/lfcs-apt-tool
dpkg-deb --build /opt/lfcs-apt-build /opt/lfcs-apt-repo/lfcs-apt-tool_1.0_all.deb >/dev/null
(cd /opt/lfcs-apt-repo && dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz)
test -s /opt/lfcs-apt-repo/Packages.gz

rm -rf /opt/lfcs-src
mkdir -p /opt/lfcs-src/lfcs-hello-1.0
cat >/opt/lfcs-src/lfcs-hello-1.0/Makefile <<'EOF'
PREFIX ?= /usr/local
all:
	printf '#!/usr/bin/env bash\necho lfcs-hello\n' > lfcs-hello
	chmod 0755 lfcs-hello
install: all
	install -d $(DESTDIR)$(PREFIX)/bin
	install -m 0755 lfcs-hello $(DESTDIR)$(PREFIX)/bin/lfcs-hello
clean:
	rm -f lfcs-hello
EOF
tar -C /opt/lfcs-src -czf /opt/lfcs-src/lfcs-hello-1.0.tar.gz lfcs-hello-1.0

systemctl enable --now docker >/dev/null 2>&1 || true
mkdir -p /opt/lfcs-docker/base
cat >/opt/lfcs-docker/base/Dockerfile <<'EOF'
FROM scratch
COPY busybox /bin/busybox
COPY message.txt /message.txt
CMD ["/bin/busybox", "sleep", "3600"]
EOF
cp /bin/busybox /opt/lfcs-docker/base/busybox
printf 'lfcs local base image\n' > /opt/lfcs-docker/base/message.txt
if command -v docker >/dev/null 2>&1; then
  docker build -t lfcs-local-base:1.0 /opt/lfcs-docker/base >/dev/null || true
  docker save lfcs-local-base:1.0 -o /opt/lfcs-docker/lfcs-local-base.tar >/dev/null 2>&1 || true
fi

mkdir -p /var/lib/libvirt/images /opt/lfcs-libvirt
cat >/opt/lfcs-libvirt/base-domain.xml <<'EOF'
<domain type='qemu'>
  <name>lfcs-template</name>
  <memory unit='MiB'>128</memory>
  <vcpu placement='static'>1</vcpu>
  <os><type arch='x86_64' machine='pc'>hvm</type></os>
  <devices><emulator>/usr/bin/qemu-system-x86_64</emulator></devices>
</domain>
EOF
sync
