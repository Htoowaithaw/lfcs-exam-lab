Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"

  config.vm.define "node1", primary: true do |node|
    node.vm.hostname = "lfcs-node1"
    node.vm.provider "virtualbox" do |vb|
      vb.name = "lfcs-node1"
      vb.memory = 4096
      vb.cpus = 2
    end
    node.vm.provision "shell", path: "provision.sh"
  end
end
