#!/bin/bash

echo "============================================="
echo "          Iniciando script master"
echo "============================================="
echo "============================================="
echo "           Configurando variables"
echo "============================================="
lbrange=($lbrange)
dev=$(ip route list | grep $ipbase | awk '{ print $3 }')
echo "KUBELET_EXTRA_ARGS=\"--node-ip=$nodeip\"" | sudo tee /etc/sysconfig/kubelet >/dev/null
sudo sed -i '/ExecStart/ a EnvironmentFile=-/etc/sysconfig/kubelet' /usr/lib/systemd/system/kubelet.service
# sudo sed -i 's/kubelet/& \$KUBELET_EXTRA_ARGS/' /usr/lib/systemd/system/kubelet.service
cat <<EOF >> /home/vagrant/.bashrc
alias k=kubectl
alias kwatch="watch kubectl get nodes,services,pods --all-namespaces -o wide --show-labels"
EOF
source $HOME/.bashrc
sudo cp -f /vagrant/scripts/kube.functions /etc/bash_completion.d/
sudo chmod 644 /etc/bash_completion.d/kube.functions
source /etc/bash_completion.d/kube.functions

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
sudo systemctl -q daemon-reload 
sudo systemctl -q enable metalLBVips.service 
sudo systemctl -q start metalLBVips.service
sudo systemctl -q restart kubelet.service 

echo "============================================="
echo "        Configurando Kubernetes"
echo "============================================="
sudo /usr/bin/kubeadm init --apiserver-advertise-address="$nodeip" \
  --pod-network-cidr="10.244.0.0/16" \
  --node-name $(hostname -s)
mkdir -p /home/vagrant/.kube
sudo cp -f /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown -R vagrant:vagrant /home/vagrant/.kube
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" | sudo tee -a /root/.bashrc >/dev/null
kubectl label node $(hostname -s) node-role.kubernetes.io/worker=worker
kubectl taint node master-node node-role.kubernetes.io/control-plane:NoSchedule-
waitPodUp k8s-app=kube-proxy kube-system

echo "============================================="
echo "          Criando arquivos para Wokers"
echo "============================================="
sudo cp -f /etc/kubernetes/admin.conf /vagrant/config/
echo "sudo $(kubeadm token create --print-join-command)" > /vagrant/scripts/join-workers.sh

echo "============================================="
echo "          Instalando o Network pod"
echo "============================================="

############################
# kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml
# waitPodUp name=weave-net kube-system
# waitPodUp k8s-app=kube-dns kube-system
# kubectl delete -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml
# sudo rm -f /etc/cni/net.d/10-weave.conflist
# sudo rm -f /opt/cni/bin/weave*
############################

############################
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
waitPodUp app=flannel kube-flannel
waitPodUp k8s-app=kube-proxy kube-system
waitPodUp k8s-app=kube-dns kube-system
# kubectl delete -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
# sudo rm -f /etc/cni/net.d/10-flannel.conflist
# sudo rm -f /opt/cni/bin/flannel*
############################

echo "============================================="
echo "           Configurando MealLB"
echo "============================================="
kubectl get configmap kube-proxy -n kube-system -o yaml |\
  sed -e "s/strictARP: false/strictARP: true/" |\
  sed -e "s/mode: \"\"/mode: \"ipvs\"/" |\
  kubectl apply -f - -n kube-system
kubectl delete pods -l k8s-app=kube-proxy -n kube-system
waitPodUp k8s-app=kube-proxy kube-system
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml
waitPodUp component=controller metallb-system
poll="$ipbase${lbrange[0]}-$ipbase${lbrange[1]}"
sed "/addresses/ a \ \ -\ $poll" /vagrant/config/deployment_l2.yaml > /vagrant/config/metallb-poll.yaml
sleep 3
kubectl apply -f /vagrant/config/metallb-poll.yaml
waitPodUp component=controller metallb-system
# kubectl delete -f https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml
# kubectl delete -f /vagrant/config/metallb-poll.yaml

echo "============================================="
echo "          Instalando o Metrics pod"
echo "============================================="

############################
kubectl apply -f https://raw.githubusercontent.com/scriptcamp/kubeadm-scripts/main/manifests/metrics-server.yaml
waitPodUp k8s-app=metrics-server kube-system
# getPodUp k8s-app=metrics-server kube-system
# getPodRunning k8s-app=metrics-server kube-system
############################

echo "============================================="
echo "          Instalando o WaveScope"
echo "============================================="

############################
kubectl apply -f https://github.com/weaveworks/scope/releases/download/v1.13.2/k8s-scope.yaml
waitPodUp app=weave-scope weave
kubectl patch svc weave-scope-app -n weave -p '{"spec": {"type": "LoadBalancer"}}'
# getPodUp app=weave-scope weave
# getPodRunning app=weave-scope weave
############################

echo "============================================="
echo "          Instalando o dashboard"
echo "============================================="

############################
wget https://raw.githubusercontent.com/tonanuvem/k8s-exemplos/master/dashboard_loadbalancer.sh
sh dashboard_loadbalancer.sh
# kubectl apply -f /vagrant/config/dashboard.yaml
# waitPodUp k8s-app=kubernetes-dashboard kubernetes-dashboard
# kubectl apply -f https://raw.githubusercontent.com/tonanuvem/k8s-exemplos/master/dashboard_permission.yml
############################


echo "============================================="
echo "         Finalizando srcipt master"
echo "============================================="
