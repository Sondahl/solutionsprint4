# -*- mode: ruby -*-
# vi: set ft=ruby :

required_plugins = %w( vagrant-vbguest )
required_plugins.each do |plugin|
  system "vagrant plugin install #{plugin}" unless Vagrant.has_plugin? plugin
end

WORKERS = 1
IPBASE = "192.168.33."
FIRSTIP = 10
LBRANGE = [100, 110]

Vagrant.configure("2") do |config|

  config.vm.box = "sondahl/solutionsprint4"
  config.vm.box_check_update = true
  config.vm.provider "virtualbox" do |vb|
    vb.memory = 2048
    vb.cpus = 2
    vb.linked_clone = true
    vb.customize ["modifyvm", :id, "--groups", "/kubernetes"]
    vb.customize ["modifyvm", :id, "--page-fusion", "on"]
    # vb.customize ["modifyvm", :id, "--nic-promisc2", "allow-all"]
    # vb.customize ["modifyvm", :id, "--cpuexecutioncap", "50"]
    # vb.customize ["modifyvm", :id, "--vram", "8"]
  end
  
  config.vm.define "master", primary: true do |master|
    master.vm.hostname = "master-node"
    master.vm.network "private_network", ip: IPBASE + "#{FIRSTIP}"
    master.vm.provision "shell", env: {"ipbase" => IPBASE, "firstip" => FIRSTIP,
      "workers" => WORKERS}, inline: $hosts
    master.vm.provision "shell", env: {"lbrange" => LBRANGE.join(" "),
      "ipbase" => IPBASE, "nodeip" => IPBASE + "#{FIRSTIP}"},
      path: "scripts/master.sh", privileged: false
  end

  (1..WORKERS).each do |i|
    config.vm.define "node-#{i}" do |node|
      node.vm.hostname = "node-#{i}"
      node.vm.network "private_network", ip: IPBASE + "#{FIRSTIP + i}"
      node.vm.provision "shell", env: {"ipbase" => IPBASE, "firstip" => FIRSTIP,
        "workers" => WORKERS}, inline: $hosts
      node.vm.provision "shell", env: {"nodeip" => IPBASE + "#{FIRSTIP + i}"},
        path: "scripts/workers.sh", privileged: false
      # if WORKERS == "#{i}"
      #   node.vm.provision "shell", inline: "echo This is the last worker"
      # end
    end
  end

end

$hosts = <<-SHELL
echo "127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4" > /etc/hosts
echo "::1         localhost localhost.localdomain localhost6 localhost6.localdomain6" >> /etc/hosts
echo "$ipbase$((firstip)) master-node" >> /etc/hosts
for (( c=1; c<=$workers; c++ )) ; do
  ip=$(($firstip+$c))
  echo "$ipbase$ip node-$c worker-node-$c" >> /etc/hosts
done
SHELL

