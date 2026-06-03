require "fileutils"

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"

  config.vm.define "node1", primary: true do |node|
    node.vm.hostname = "lfcs-node1"
    node.vm.provider "virtualbox" do |vb|
      vb.name = "lfcs-node1"
      vb.memory = 4096
      vb.cpus = 2
      scratch_dir = File.join(Dir.pwd, ".vagrant", "scratch-disks")
      FileUtils.mkdir_p(scratch_dir)
      (1..8).each do |idx|
        disk = File.join(scratch_dir, "lfcs-node1-scratch#{idx}.vdi")
        unless File.exist?(disk)
          vb.customize ["createhd", "--filename", disk, "--size", 1024]
        end
        vb.customize [
          "storageattach", :id,
          "--storagectl", "SATA Controller",
          "--port", idx,
          "--device", 0,
          "--type", "hdd",
          "--medium", disk
        ]
      end
    end
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
