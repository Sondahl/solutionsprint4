#!/bin/bash

echo "============================================="
echo "          Iniciando script workers"
echo "============================================="
source /etc/bash_completion.d/kube.functions
dev=$(ip route list | grep $ipbase | awk '{ print $3 }')
export KUBE_PROXY_MODE=ipvs

echo "============================================="
echo "          Configurando MetalLB VIPs"
echo "============================================="
echo "OPTS=\"${lbrange[0]} ${lbrange[1]} $dev\"" | sudo tee /etc/sysconfig/metalLBVips >/dev/null
sudo cp -f /vagrant/scripts/metalLBVips /usr/local/bin/
sudo chmod 755 /usr/local/bin/metalLBVips
sudo cp -f /vagrant/config/metalLBVips.service /etc/systemd/system/

echo "============================================="
echo "            Reload systemctl"
echo "============================================="
sudo systemctl daemon-reload 
sudo systemctl -q enable metalLBVips.service 
sudo systemctl -q start metalLBVips.service

echo "============================================="
echo "        Configurando Kubernetes"
echo "============================================="
bash /vagrant/scripts/join-workers.sh

mkdir -p /home/vagrant/.kube
cp -f /vagrant/config/admin.conf /home/vagrant/.kube/config
sudo chown -R vagrant:vagrant /home/vagrant/.kube

kubectl label node $(hostname -s) node-role.kubernetes.io/worker=
waitPodUp k8s-app=kube-proxy kube-system
waitPodUp name=weave-net kube-system

echo "============================================="
echo "         Configurando MetalLB VIPs"
echo "============================================="
echo "OPTS=\"$ipbase $lbfirstip $(($lbfirstip+$lbipsperhost)) $dev\"" | sudo tee /etc/sysconfig/metalLBVips >/dev/null
sudo cp -f /vagrant/scripts/metalLBVips /usr/local/bin/
sudo chmod 755 /usr/local/bin/metalLBVips
sudo cp -f /vagrant/config/metalLBVips.service /etc/systemd/system/
sudo systemctl daemon-reload 
sudo systemctl -q enable metalLBVips.service 
sudo systemctl -q start metalLBVips.service

echo "============================================="
echo "  Configurando Pool para o host: $(hostname -s)"
echo "============================================="
rm -f /vagrant/config/pool-$(hostname -s).yaml
poll="$ipbase.$lbfirstip-$ipbase.$(($lbfirstip+$lbipsperhost))"
sed "s/IPPOLL/$poll/g;s/NODENAME/$(hostname -s)/g;s/INTERFACE/$dev/g" /vagrant/config/metallb-base.yaml > /vagrant/config/pool-$(hostname -s).yaml

echo "============================================="
echo "        Finalizando script workers"
echo "============================================="
