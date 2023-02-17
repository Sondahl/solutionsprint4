# -*- mode: ruby -*-
# vi: set ft=ruby :

required_plugins = %w( vagrant-vbguest )
required_plugins.each do |plugin|
  system "vagrant plugin install #{plugin}" unless Vagrant.has_plugin? plugin
end

workers = 1
ipbase = "192.168.33"
firstip = 10
lbfirstip = 100
lbipsperhost = 9

vmsmem = 2048
vmscpu = 2

Vagrant.configure("2") do |config|
  config.vm.box = "sondahl/solutionsprint4"
  config.vm.box_check_update = true
  config.vm.provider "virtualbox" do |vb|
    vb.linked_clone = true
    vb.memory = vmsmem
    vb.cpus = vmscpu
    vb.customize ["modifyvm", :id, "--groups", "/kubernetes"]
    vb.customize ["modifyvm", :id, "--nic-type2", "82545EM"]
    vb.customize ["modifyvm", :id, "--audio", "none"]
    vb.customize ["modifyvm", :id, "--page-fusion", "on"]
  end
  config.vm.synced_folder ".", "/vagrant", type: "virtualbox"

  config.vm.define "master", primary: true do |master|
    # master.vm.provider "virtualbox" do |vb|
    #   vb.cpus = "#{vmscpu * 2}"
    # end
    master.vm.hostname = "master.local"
    master.vm.network "private_network", ip: ipbase + ".#{firstip}"

    master.vm.provision "master-common", type: "shell",
      env: {"ipbase" => ipbase, "firstip" => firstip, "workers" => workers,
        "nodeip" => ipbase + ".#{firstip}"},
      path: "scripts/common.sh", privileged: true
    
    master.vm.provision "master-master", type: "shell",
      env: {"ipbase" => ipbase, "firstip" => firstip, "workers" => workers,
          "nodeip" => ipbase + ".#{firstip}",
          "lbfirstip" => lbfirstip, "lbipsperhost" => lbipsperhost},
      path: "scripts/master.sh", privileged: false

    if workers < 1
      master.vm.provision "reset", type: "shell", reset: true
      master.vm.provision "master-finishing", type: "shell",
        path: "scripts/finishing.sh", privileged: false
    end
    # lbfirstip += lbipsperhost + 1
  end
  (1...workers).each do |i|
    config.vm.define "node-#{i}" do |node|
      # node.vm.provider "virtualbox" do |vb|
      #   vb.cpus = "#{vmscpu * 2}"
      #   # vb.memory = "#{vmsmem * 2}"
      # end
      node.vm.hostname = "node-#{i}.local"
      node.vm.network "private_network", ip: ipbase + ".#{firstip + i}"

      node.vm.provision "worker#{i}-common", type: "shell",
        env: {"ipbase" => ipbase, "firstip" => firstip, "workers" => workers,
          "nodeip" => ipbase + ".#{firstip + i}"},
        path: "scripts/common.sh", privileged: true

      node.vm.provision "reset", type: "shell", reset: true
      node.vm.provision "worker#{i}-workers", type: "shell",
        env: {"ipbase" => ipbase, "firstip" => firstip, "workers" => workers,
          "nodeip" => ipbase + ".#{firstip + i}"},
        path: "scripts/workers.sh", privileged: false
    end
  end
  if workers >= 1
    config.vm.define "node-#{workers}" do |node|
      # node.vm.provider "virtualbox" do |vb|
      #   vb.cpus = "#{vmscpu * 2}"
      #   # vb.memory = "#{vmsmem * 2}"
      # end
      node.vm.hostname = "node-#{workers}.local"
      node.vm.network "private_network", ip: ipbase + ".#{firstip + workers}"

      node.vm.provision "worker#{workers}-common", type: "shell",
        env: {"ipbase" => ipbase, "firstip" => firstip, "workers" => workers,
          "nodeip" => ipbase + ".#{firstip + workers}"},
        path: "scripts/common.sh", privileged: true

      node.vm.provision "reset", type: "shell", reset: true
      node.vm.provision "worker#{workers}-workers", type: "shell",
        env: {"ipbase" => ipbase, "firstip" => firstip, "workers" => workers,
          "nodeip" => ipbase + ".#{firstip + workers}"},
        path: "scripts/workers.sh", privileged: false

      node.vm.provision "worker#{workers}-finishing", type: "shell",
        path: "scripts/finishing.sh", privileged: false
    end
  end
end
