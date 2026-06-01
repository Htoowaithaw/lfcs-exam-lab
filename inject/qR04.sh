#!/usr/bin/env bash
set -euo pipefail
dnf -y remove lfcs-r04-tool >/dev/null 2>&1 || true
rm -f /etc/yum.repos.d/lfcs-r04.repo
rm -rf /opt/lfcs-r04-build /opt/lfcs-r04-repo
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
dnf -y install rpm-build createrepo_c >/dev/null
rpmbuild --define '_topdir /opt/lfcs-r04-build' -bb /opt/lfcs-r04-build/SPECS/lfcs-r04-tool.spec >/dev/null
mkdir -p /opt/lfcs-r04-repo
cp /opt/lfcs-r04-build/RPMS/noarch/lfcs-r04-tool-1.0-1*.rpm /opt/lfcs-r04-repo/
createrepo_c /opt/lfcs-r04-repo >/dev/null
dnf clean all >/dev/null
