#!/usr/bin/env bash
# Assigns a static IP to the second NIC (the VirtualBox NAT Network adapter
# added via the Vagrantfile's `--nic2 natnetwork` customize call) so node1
# and node2 can reach each other on the lab's private subnet. Deliberately
# NOT using Vagrant's built-in `private_network` helper - that targets a
# host-only adapter, which needs a macOS system-extension approval that
# some managed/MDM Macs block outright. NAT Network needs no such approval.
#
# Verified end-to-end (ping + raw TCP:22 - the same check
# labkit/providers/vagrant.py's wait_peer() uses) on an Apple Silicon Mac
# under a managed, system-extension-restricted profile.
#
# Only node1/node2 (both bento/ubuntu-22.04) use this script; lfcs-rocky1
# doesn't participate in peer networking.
set -euo pipefail

IP="$1"

IFACE=""
for dev in /sys/class/net/*; do
  n=$(basename "$dev")
  [ "$n" = "lo" ] && continue
  if ! ip -4 addr show dev "$n" | grep -q "inet "; then
    IFACE="$n"
    break
  fi
done

if [ -z "$IFACE" ]; then
  echo "provision-natnet-static: no unconfigured interface found - already configured or NIC2 missing?" >&2
  exit 0
fi

echo "==> Assigning $IP/24 to $IFACE"
cat > /etc/netplan/90-natnet-static.yaml <<EOF
network:
  version: 2
  ethernets:
    ${IFACE}:
      dhcp4: no
      addresses: [${IP}/24]
EOF
chmod 600 /etc/netplan/90-natnet-static.yaml
netplan apply
sleep 1
ip -4 addr show dev "$IFACE"
