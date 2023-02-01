#!/bin/bash

lbrange=($lbrange)

echo "============================================="
echo "          Iniciando script workers"
echo "============================================="
echo "============================================="
echo "           Configurando variables"
echo "============================================="
cat <<EOF >> /home/vagrant/.bashrc
alias k=kubectl
alias kwatch="watch kubectl get nodes,services,pods --all-namespaces -o wide --show-labels"
EOF
source $HOME/.bashrc
sudo cp -f /vagrant/scripts/kube.functions /etc/bash_completion.d/
sudo chmod 644 /etc/bash_completion.d/kube.functions
source /etc/bash_completion.d/kube.functions
echo "KUBELET_EXTRA_ARGS=\"--node-ip=$nodeip\"" | sudo tee /etc/sysconfig/kubelet >/dev/null 2>&1
sudo sed -i '/ExecStart/ a EnvironmentFile=-/etc/sysconfig/kubelet' /usr/lib/systemd/system/kubelet.service
# sudo sed -i 's/kubelet/& \$KUBELET_EXTRA_ARGS/' /usr/lib/systemd/system/kubelet.service

echo "============================================="
echo "            Reload systemctl"
echo "============================================="
sudo systemctl daemon-reload 
sudo systemctl restart kubelet.service 

echo "============================================="
echo "        Configurando Kubernetes"
echo "============================================="
/vagrant/scripts/join-workers.sh
mkdir -p /home/vagrant/.kube
cp -f /vagrant/config/admin.conf /home/vagrant/.kube/config
sudo chown -R vagrant:vagrant /home/vagrant/.kube
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" | sudo tee -a /root/.bashrc >/dev/null 2>&1
kubectl label node $(hostname -s) node-role.kubernetes.io/worker=worker
waitPodUp k8s-app=kube-proxy kube-system

echo "============================================="
echo "        Finalizando script workers"
echo "============================================="
