require "fileutils"

# Inter-node networking (node1 <-> node2) uses a VirtualBox NAT Network
# rather than a host-only adapter, on every host platform. Host-only needs
# a host-level network driver (a macOS system-extension approval, blocked
# outright on some managed/MDM Macs) that NAT Network doesn't need at all -
# it's a fully software-defined switch inside VirtualBox itself. Verified
# end-to-end through the real harness on an Apple Silicon Mac under a
# managed, system-extension-restricted profile: q225 (real two-node
# question, exercises wait_peer() in labkit/providers/vagrant.py) and q094
# (libvirt domain define) both PASS/PASS/PASS/PASS. This choice is kept
# universal rather than Apple-Silicon-only to keep the Vagrantfile on one
# code path - see commit history for the switch from host-only.
# lfcs-rocky1 doesn't participate in peer networking either way (see _PEER
# in labkit/providers/vagrant.py).
NATNET_NAME = "lfcs-exam-lab-net"
NATNET_CIDR = "192.168.56.0/24"

# arm64 Apple Silicon VirtualBox builds attach bento's arm64 boxes to a
# "VirtIO Controller" (VirtioSCSI); amd64 builds use "SATA Controller"
# (AHCI). Verified directly via VBoxManage showvminfo on a freshly imported
# arm64 bento box. If a future box build changes this, `VBoxManage
# showvminfo lfcs-node1 | grep -i controller` on the host tells you the
# real name.
STORAGE_CONTROLLER = RUBY_PLATFORM.include?("arm64") ? "VirtIO Controller" : "SATA Controller"

# Create the shared NAT Network once, idempotently, before any VM-affecting
# command. Harmless/no-op if it already exists.
if %w[up reload provision].include?(ARGV[0])
  existing = `VBoxManage natnetwork list 2>/dev/null`
  unless existing.include?(NATNET_NAME)
    system("VBoxManage", "natnetwork", "add", "--netname", NATNET_NAME, "--network", NATNET_CIDR, "--enable")
    system("VBoxManage", "natnetwork", "modify", "--netname", NATNET_NAME, "--dhcp", "off")
  end
end

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"

  config.vm.define "node1", primary: true do |node|
    node.vm.hostname = "lfcs-node1"
    node.vm.provider "virtualbox" do |vb|
      vb.name = "lfcs-node1"
      vb.memory = 4096
      vb.cpus = 2
      vb.customize ["modifyvm", :id, "--nic2", "natnetwork", "--nat-network2", NATNET_NAME]
      scratch_dir = File.join(Dir.pwd, ".vagrant", "scratch-disks")
      FileUtils.mkdir_p(scratch_dir)
      (1..8).each do |idx|
        disk = File.join(scratch_dir, "lfcs-node1-scratch#{idx}.vdi")
        unless File.exist?(disk)
          vb.customize ["createhd", "--filename", disk, "--size", 1024]
        end
        vb.customize [
          "storageattach", :id,
          "--storagectl", STORAGE_CONTROLLER,
          "--port", idx,
          "--device", 0,
          "--type", "hdd",
          "--medium", disk
        ]
      end
    end
    node.vm.provision "shell", path: "provision-natnet-static.sh", args: ["192.168.56.11"]
    node.vm.provision "shell", path: "provision.sh"
  end

  config.vm.define "node2" do |node|
    node.vm.box = "bento/ubuntu-22.04"
    node.vm.hostname = "lfcs-node2"
    node.vm.provider "virtualbox" do |vb|
      vb.name = "lfcs-node2"
      vb.memory = 3072
      vb.cpus = 2
      vb.customize ["modifyvm", :id, "--nic2", "natnetwork", "--nat-network2", NATNET_NAME]
    end
    node.vm.provision "shell", path: "provision-natnet-static.sh", args: ["192.168.56.12"]
    node.vm.provision "shell", path: "provision.sh"
  end

  config.vm.define "lfcs-rocky1" do |rocky|
    rocky.vm.box = "bento/rockylinux-9"
    rocky.vm.hostname = "lfcs-rocky1"
    rocky.vm.provider "virtualbox" do |vb|
      vb.name = "lfcs-rocky1"
      vb.memory = 4096
      vb.cpus = 2
    end
    rocky.vm.provision "shell", path: "provision-rocky.sh"
  end
end
