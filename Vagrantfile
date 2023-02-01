# -*- mode: ruby -*-
# vi: set ft=ruby :

# ENV['VAGRANT_EXPERIMENTAL'] = "dependency_provisioners"

required_plugins = %w( vagrant-vbguest )
required_plugins.each do |plugin|
  system "vagrant plugin install #{plugin}" unless Vagrant.has_plugin? plugin
end

WORKERS = 0
IPBASE = "192.168.33."
FIRSTIP = 10
LBRANGE = [100, 110]

Vagrant.configure("2") do |config|

  config.vm.box = "sondahl/solutionsprint4"
  config.vm.box_check_update = true
  config.vm.provider "virtualbox" do |vb|
    vb.linked_clone = true
    vb.memory = 2048
    vb.cpus = 2
    vb.customize ["modifyvm", :id, "--groups", "/kubernetes"]
    vb.customize ["modifyvm", :id, "--nic-type2", "82545EM"]
    vb.customize ["modifyvm", :id, "--audio", "none"]
    vb.customize ["modifyvm", :id, "--graphicscontroller", "vmsvga"]
  end
  config.vm.synced_folder ".", "/vagrant", type: "virtualbox"

  config.vm.define "master", primary: true do |master|
    master.vm.hostname = "master-node"
    master.vm.network "private_network", ip: IPBASE + "#{FIRSTIP}"

    master.vm.provision "master1", type: "shell",
      env: {"ipbase" => IPBASE, "firstip" => FIRSTIP, "workers" => WORKERS},
      inline: $hosts

    master.vm.provision "master2", type: "shell",
      env: {"ipbase" => IPBASE, "lbrange" => LBRANGE.join(" "), "nodeip" => IPBASE + "#{FIRSTIP}"},
      path: "scripts/master.sh", privileged: false

    # master.vm.provision "master3", type: "shell",
    #   env: {"ipbase" => IPBASE, "lbrange" => LBRANGE.join(" "), "workers" => WORKERS},
    #   path: "scripts/finishing.sh", privileged: false
  end
  (1..WORKERS).each do |i|
    config.vm.define "worker-node-#{i}" do |node|
      node.vm.hostname = "worker-node-#{i}"
      node.vm.network "private_network", ip: IPBASE + "#{FIRSTIP + i}"

      node.vm.provision "worker#{i}-1", type: "shell",
        env: {"ipbase" => IPBASE, "firstip" => FIRSTIP, "workers" => WORKERS},
        inline: $hosts

      node.vm.provision "worker#{i}-2", type: "shell",
        env: {"nodeip" => IPBASE + "#{FIRSTIP + i}", "lbrange" => LBRANGE.join(" "),
        "workers" => WORKERS, "ipbase" => IPBASE},
        path: "scripts/workers.sh", privileged: false
    end
  end
  # config.vm.define "node-#{WORKERS}" do |node|
  #   node.vm.hostname = "node-#{WORKERS}.local"
  #   node.vm.network "private_network", ip: IPBASE + "#{FIRSTIP + WORKERS}"

  #   # node.vm.provision "worker#{WORKERS}-1", type: "shell",
  #   #   env: {"ipbase" => IPBASE, "firstip" => FIRSTIP, "workers" => WORKERS},
  #   #   inline: $hosts

  #   # node.vm.provision "worker#{WORKERS}-2", type: "shell",
  #   #   env: {"nodeip" => IPBASE + "#{FIRSTIP + i}", "lbrange" => LBRANGE.join(" "),
  #   #   "workers" => WORKERS, "ipbase" => IPBASE},
  #   #   path: "scripts/workers.sh", privileged: false
  # end
end

$hosts = <<-SHELL
echo "127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4" > /etc/hosts
echo "::1         localhost localhost.localdomain localhost6 localhost6.localdomain6" >> /etc/hosts
echo "$ipbase$((firstip)) master-node master" >> /etc/hosts
for (( c=1; c<=$workers; c++ )) ; do
  ip=$(($firstip+$c))
  echo "$ipbase$ip worker-node-$c node-$c " >> /etc/hosts
done
SHELL

