#!/bin/bash

cat /vagrant/config/hosts | sudo tee -a /etc/hosts

sudo setenforce 0
sudo sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
sudo swapoff -a
sudo sed -i.bak -r 's/(.+ swap .+)/#\1/' /etc/fstab

sudo timedatectl set-timezone America/Sao_Paulo
sudo sed -i '1 s/^/server a.st1.ntp.br iburst\nserver b.st1.ntp.br iburst\nserver c.st1.ntp.br iburst\nserver d.st1.ntp.br iburst\nserver a.ntp.br iburst\nserver b.ntp.br iburst\nserver c.ntp.br iburst\nserver gps.ntp.br iburst\n/' /etc/chrony.conf
sudo systemctl restart chronyd

sudo cp -f /vagrant/config/k8s.conf /etc/modules-load.d/
sudo modprobe br_netfilter
sudo modprobe overlay
sudo modprobe ip_conntrack
sudo modprobe dummy

sudo cp -f /vagrant/config/99-k8s.conf /etc/sysctl.d/
sysctl --system

sudo systemctl start firewalld.service
sudo systemctl enable firewalld.service
sudo firewall-cmd --set-default-zone=public
sudo firewall-cmd --permanent --add-service=dns
sudo firewall-cmd --permanent --add-service=dhcp
sudo firewall-cmd --permanent --add-service=dhcpv6-client
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --permanent --add-port=2379-2380/tcp
sudo firewall-cmd --permanent --add-port=6443/tcp
sudo firewall-cmd --permanent --add-port=6783/tcp
sudo firewall-cmd --permanent --add-port=6783/udp
sudo firewall-cmd --permanent --add-port=6784/udp
sudo firewall-cmd --permanent --add-port=10250/tcp
sudo firewall-cmd --permanent --add-port=10251/tcp
sudo firewall-cmd --permanent --add-port=10252/tcp
sudo firewall-cmd --permanent --add-port=10255/tcp
sudo firewall-cmd --permanent --add-port=30000-32767/tcp
sudo firewall-cmd --permanent --add-port=7946/tcp
sudo firewall-cmd --permanent --add-port=7946/udp
sudo firewall-cmd --reload

sudo yum-config-manager \
  --add-repo \
  https://download.docker.com/linux/centos/docker-ce.repo

sudo cp -f /vagrant/config/kubernetes.repo /etc/yum.repos.d/

sudo yum install -y https://packages.endpointdev.com/rhel/7/os/x86_64/endpoint-repo.x86_64.rpm

sudo yum groupinstall -y -q "Minimal Install" "Development Tools"
sudo yum install -y nc nmap telnet traceroute net-tools bind-utils\
 bash-completion wget yum-utils device-mapper-persistent-data lvm2\
 golang cri ebtables ipset containerd.io kubelet kubeadm kubectl
#  docker-ce docker-compose kubelet kubeadm kubectl

# sudo systemctl enable --now docker
# sudo systemctl start docker
sudo systemctl enable --now containerd
sudo systemctl start containerd
sudo systemctl enable --now kubelet
sudo systemctl start kubelet

# sudo cp -f /vagrant/config/daemon.json /etc/docker/
sudo mv -f /etc/containerd/config.toml /etc/containerd/config.toml_orig
sudo containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# sudo systemctl restart docker
sudo systemctl restart containerd
sudo systemctl restart kubelet

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl-convert"\
 -p /tmp
curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl-convert.sha256"\
 -p /tmp
echo "$(cat /tmp/kubectl-convert.sha256) /tmp/kubectl-convert" | sha256sum --check
if [ $? -eq 0 ] ; then
  sudo install -o root -g root -m 0755 /tmp/kubectl-convert /usr/local/bin/kubectl-convert
fi

kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl.bash > /dev/null
kubeadm completion bash | sudo tee /etc/bash_completion.d/kubeadm.bash > /dev/null
