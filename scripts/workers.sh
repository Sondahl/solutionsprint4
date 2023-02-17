#!/bin/bash

echo "============================================="
echo "          Iniciando script workers"
echo "============================================="
source /etc/bash_completion.d/kube.functions
export KUBE_PROXY_MODE=ipvs

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
echo "        Finalizando script workers"
echo "============================================="
