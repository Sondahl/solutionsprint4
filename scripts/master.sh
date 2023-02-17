#!/bin/bash

echo "============================================="
echo "          Iniciando script master"
echo "============================================="
source /etc/bash_completion.d/kube.functions
dev=$(ip route list | grep $ipbase | awk '{ print $3 }')
export KUBE_PROXY_MODE=ipvs
        
echo "============================================="
echo "        Configurando Kubernetes"
echo "============================================="
sudo kubeadm init --apiserver-advertise-address="$nodeip" \
  --pod-network-cidr="10.244.0.0/16" \
  --service-cidr="10.96.0.0/12" \
  --node-name=$(hostname -s) 

mkdir -p /home/vagrant/.kube
sudo cp -f /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown -R vagrant:vagrant /home/vagrant/.kube

if [ $workers -lt 1 ] ; then
  kubectl label node $(hostname -s) node-role.kubernetes.io/worker=
  kubectl taint node $(hostname -s) node-role.kubernetes.io/control-plane:NoSchedule-
fi
sleep 5
waitPodUp component=kube-apiserver kube-system
waitPodUp component=kube-controller-manager kube-system
waitPodUp component=etcd kube-system
waitPodUp k8s-app=kube-proxy kube-system

echo "============================================="
echo "          Criando arquivos para Wokers"
echo "============================================="
rm -f /vagrant/config/admin.conf
sudo cp -f /etc/kubernetes/admin.conf /vagrant/config/
rm -f /vagrant/scripts/join-workers.sh
echo "sudo $(kubeadm token create --print-join-command) --node-name=\$(hostname -s)" > /vagrant/scripts/join-workers.sh

echo "============================================="
echo "      Configurando IPVS para o kube-proxy"
echo "============================================="
kubectl get configmap kube-proxy -n kube-system -o yaml |\
  sed -e "s/strictARP: false/strictARP: true/" |\
  sed -e "s/mode: \"\"/mode: \"ipvs\"/" |\
  kubectl apply -f - -n kube-system
kubectl delete pods -l k8s-app=kube-proxy -n kube-system
waitPodUp k8s-app=kube-proxy kube-system

echo "============================================="
echo "        Instalando o Network weave"
echo "============================================="
kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml
waitPodUp name=weave-net kube-system
waitPodUp k8s-app=kube-dns kube-system

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
echo "          Instalando o Metrics pod"
echo "============================================="
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
waitPodUp k8s-app=metrics-server kube-system

echo "============================================="
echo "         Finalizando srcipt master"
echo "============================================="
