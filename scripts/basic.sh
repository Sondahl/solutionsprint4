#!/bin/bash

cat /vagrant/config/hosts | sudo tee -a /etc/hosts

sudo setenforce 0
sudo sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
sudo swapoff -a
sudo sed -i '/swap/ s/^/#/' /etc/fstab

sudo timedatectl set-timezone America/Sao_Paulo
sudo sed -i '1 s/^/server a.st1.ntp.br iburst\nserver b.st1.ntp.br iburst\nserver c.st1.ntp.br iburst\nserver d.st1.ntp.br iburst\nserver a.ntp.br iburst\nserver b.ntp.br iburst\nserver c.ntp.br iburst\nserver gps.ntp.br iburst\n/' /etc/chrony.conf
sudo systemctl restart chronyd

sudo cp -f /vagrant/config/k8s.conf /etc/modules-load.d/
sudo modprobe br_netfilter
sudo modprobe overlay
sudo modprobe ip_conntrack

sudpcp cp -f  /vagrant/config/99-k8s.conf /etc/sysctl.d/
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

yum install -y https://packages.endpointdev.com/rhel/7/os/x86_64/endpoint-repo.x86_64.rpm

yum groupinstall -y "Minimal Install" "Development Tools"

