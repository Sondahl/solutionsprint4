#!/bin/bash

LOG=/tmp/deployVagrant.log

cat << EOF | sudo tee /etc/modules-load.d/99-k8s-modules.conf
br_netfilter
overlay
EOF
sudo modprobe br_netfilter
sudo modprobe overlay

cat << EOF | sudo tee /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
192.168.33.10 master-node
192.168.33.11 node-1 worker-node-1
192.168.33.12 node-2 worker-node-2
EOF

sudo setenforce 0
sudo sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
sudo swapoff -a
sudo sed -i -r 's/(.+ swap .+)/#\1/' /etc/fstab

sudo timedatectl set-timezone America/Sao_Paulo
sudo sed -i '1 s/^/server gps.ntp.br iburst\n/' /etc/chrony.conf
sudo sed -i '1 s/^/server c.st1.ntp.br iburst\nserver d.st1.ntp.br iburst\n/' /etc/chrony.conf
sudo sed -i '1 s/^/server a.st1.ntp.br iburst\nserver b.st1.ntp.br iburst\n/' /etc/chrony.conf
sudo systemctl restart chronyd

cat << EOF | sudo tee /etc/sysctl.d/99-k8s-sysctl.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system

sudo systemctl enable --now firewalld
sudo systemctl start firewalld
# sudo firewall-cmd --permanent --zone=public --change-interface=eth0
# sudo firewall-cmd --permanent --zone=public --add-service=dhcp
# sudo firewall-cmd --permanent --zone=public --add-service=dhcpv6-client
# sudo firewall-cmd --permanent --zone=public --add-service=ssh
# sudo firewall-cmd --permanent --zone=public --add-masquerade
sudo firewall-cmd --permanent --set-default-zone=trusted
sudo firewall-cmd --permanent --zone=trusted --change-interface=eth1 
sudo firewall-cmd --permanent --zone=trusted --add-service=dhcp
sudo firewall-cmd --permanent --zone=trusted --add-service=dhcpv6-client
sudo firewall-cmd --permanent --zone=trusted --add-service=dns
sudo firewall-cmd --permanent --zone=trusted --add-service=etcd-client
sudo firewall-cmd --permanent --zone=trusted --add-service=etcd-server
sudo firewall-cmd --permanent --zone=trusted --add-service=git
sudo firewall-cmd --permanent --zone=trusted --add-service=http
sudo firewall-cmd --permanent --zone=trusted --add-service=https
sudo firewall-cmd --permanent --zone=trusted --add-service=samba-client
sudo firewall-cmd --permanent --zone=trusted --add-service=ssh
sudo firewall-cmd --permanent --zone=trusted --add-service=snmp
sudo firewall-cmd --permanent --zone=trusted --add-service=ntp
sudo firewall-cmd --permanent --zone=trusted --add-port=2379-2380/tcp # Kubernetes etcd server client API
sudo firewall-cmd --permanent --zone=trusted --add-port=8285/udp # Flannel
sudo firewall-cmd --permanent --zone=trusted --add-port=6443/tcp # Kubernetes API server
sudo firewall-cmd --permanent --zone=trusted --add-port=6783/tcp # etcd server client API
sudo firewall-cmd --permanent --zone=trusted --add-port=6783/udp # Weave
sudo firewall-cmd --permanent --zone=trusted --add-port=6784/udp # Weave
sudo firewall-cmd --permanent --zone=trusted --add-port=8090/tcp # Platform Agent
sudo firewall-cmd --permanent --zone=trusted --add-port=8091/tcp # Platform API Server 
sudo firewall-cmd --permanent --zone=trusted --add-port=8472/udp # Flannel
sudo firewall-cmd --permanent --zone=trusted --add-port=10250/tcp # Kubelet API
sudo firewall-cmd --permanent --zone=trusted --add-port=10251/tcp # kube-scheduler
sudo firewall-cmd --permanent --zone=trusted --add-port=10252/tcp # kube-controller-manager
sudo firewall-cmd --permanent --zone=trusted --add-port=10255/tcp # Kubelet API
sudo firewall-cmd --permanent --zone=trusted --add-port=30000-32767/tcp # NodePorts exposed on control plane IP as well
sudo firewall-cmd --reload

sudo yum-config-manager -y -q \
  --add-repo \
  https://download.docker.com/linux/centos/docker-ce.repo

cat << EOF | sudo tee /etc/yum.repos.d/kubernetes.repo >/dev/null 2>&1
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

sudo yum install -y -q https://packages.endpointdev.com/rhel/7/os/x86_64/endpoint-repo.x86_64.rpm
sudo yum-config-manager -y -q --enable centosplus >/dev/null 2>&1
sudo yum install -y -q epel-release

sudo yum install -y -q nc nmap telnet traceroute net-tools bind-utils\
 htop jq golang perl lvm2 wget arptables ipvsadm\
 containerd.io kubelet kubeadm kubectl --disableexcludes=kubernetes
# device-mapper-persistent-data  cri-tools 

wget -nv http://download.virtualbox.org/virtualbox/7.0.6/VBoxGuestAdditions_7.0.6.iso -P /tmp
sudo mount -o loop,ro /tmp/VBoxGuestAdditions_7.0.6.iso /media
sudo sh /media/VBoxLinuxAdditions.run
sudo umount /media
rm -f /tmp/VBoxGuestAdditions_7.0.6.iso

sudo systemctl enable --now containerd
sudo systemctl start containerd
sudo systemctl enable --now kubelet
sudo systemctl start kubelet

sudo mv -f /etc/containerd/config.toml /etc/containerd/config.toml_orig
sudo containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

sudo systemctl restart containerd
sudo systemctl restart kubelet

wget -nv "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl-convert"\
 -P /tmp
wget -nv  "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl-convert.sha256"\
 -P /tmp
echo "$(cat /tmp/kubectl-convert.sha256) /tmp/kubectl-convert" | sha256sum --check
if [ $? -eq 0 ] ; then
  sudo install -o root -g root -m 0755 /tmp/kubectl-convert /usr/local/bin/kubectl-convert
fi
rm -f /tmp/kubectl*

kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl.bash > /dev/null
kubeadm completion bash | sudo tee /etc/bash_completion.d/kubeadm.bash > /dev/null

exit 0