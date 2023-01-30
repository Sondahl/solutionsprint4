#!/bin/bash

{
lbrange=($lbrange)
dev=$(ip route list | grep $ipbase | awk '{ print $3 }')

unalias cp
ssh-keygen -t rsa -N '' -C vagrant -f /home/vagrant/.ssh/id_rsa <<< y  >/dev/null 2>&1
cat /home/vagrant/.ssh/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys
cp -f /home/vagrant/.ssh/id_rsa /vagrant/config/vagrant_id_rsa
cp -f /home/vagrant/.ssh/id_rsa.pub /vagrant/config/vagrant_id_rsa.pub

sudo ssh-keygen -t rsa -N '' -C root -f /root/.ssh/id_rsa <<< y  >/dev/null 2>&1
sudo cp -f /root/.ssh/id_rsa /vagrant/config/root_id_rsa
sudo cp -f /root/.ssh/id_rsa.pub /vagrant/config/root_id_rsa.pub
sudo cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys

echo "KUBELET_EXTRA_ARGS=\"--node-ip=$nodeip\"" | sudo tee /etc/sysconfig/kubelet
sudo sed -i 's/kubelet/& \$KUBELET_EXTRA_ARGS/' /usr/lib/systemd/system/kubelet.service
sudo sed -i '/ExecStart/ a EnvironmentFile=-/etc/sysconfig/kubelet' /usr/lib/systemd/system/kubelet.service

sudo systemctl daemon-reload 
sudo systemctl restart kubelet.service && sleep 1 

cat <<EOF | tee -a /home/vagrant/.bashrc
alias k=kubectl
alias kwatch="watch kubectl get nodes,services,pods --all-namespaces -o wide --show-labels"
EOF
. $HOME/.bashrc
sudo cp -f /vagrant/scripts/kube.functions /etc/bash_completion.d/
. /etc/bash_completion.d/kube.functions

sudo /usr/bin/kubeadm init --apiserver-advertise-address="$nodeip" \
  --pod-network-cidr="10.244.0.0/16" \
  --node-name $(hostname -s)
mkdir -p /home/vagrant/.kube
sudo cp -f /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown -R vagrant:vagrant /home/vagrant/.kube
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" | sudo tee -a /root/.bashrc

waitPodUp k8s-app=kube-proxy kube-system

sudo cp -f /etc/kubernetes/admin.conf /vagrant/config/
sudo rm -f /vagrant/scripts/workers.sh
cat <<EOF | sudo tee -a /vagrant/scripts/workers.sh
#!/bin/bash

{
unalias cp
cp -f /vagrant/config/vagrant_id_rsa /home/vagrant/.ssh/id_rsa
cp -f /vagrant/config/vagrant_id_rsa.pub /home/vagrant/.ssh/id_rsa.pub 
cat /home/vagrant/.ssh/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys

sudo mkdir -p /root/.ssh
sudo cp -f /vagrant/config/root_id_rsa /root/.ssh/id_rsa
sudo cp -f /vagrant/config/root_id_rsa.pub /root/.ssh/id_rsa.pub 
cat /root/.ssh/id_rsa.pub | sudo tee /root/.ssh/authorized_keys >/dev/null 2>&1
sudo chmod 700 /root/.ssh
sudo chmod 600 /root/.ssh/id_rsa
sudo chmod 644 /root/.ssh/id_rsa.pub

cat <<EOF2 | tee -a /home/vagrant/.bashrc
alias k=kubectl
alias kwatch="watch kubectl get nodes,services,pods --all-namespaces -o wide --show-labels"
EOF2
. \$HOME/.bashrc
sudo cp -f /vagrant/scripts/kube.functions /etc/bash_completion.d/
. /etc/bash_completion.d/kube.functions
mkdir -p /home/vagrant/.kube
echo "KUBELET_EXTRA_ARGS=\"--node-ip=\$nodeip\"" | sudo tee /etc/sysconfig/kubelet

sudo $(kubeadm token create --print-join-command)
cp -f /vagrant/config/admin.conf /home/vagrant/.kube/config
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" | sudo tee -a /root/.bashrc
sudo chown -R vagrant:vagrant /home/vagrant/.kube
kubectl label node \$(hostname -s) node-role.kubernetes.io/worker=worker
}
exit \$?
EOF

############################
# kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml
# getPodUp name=weave-net kube-system
# getPodRunning name=weave-net kube-system
# getPodUp k8s-app=kube-dns kube-system
# getPodRunning k8s-app=kube-dns kube-system
# kubectl delete -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml
# sudo rm -f /etc/cni/net.d/10-weave.conflist
# sudo rm -f /opt/cni/bin/weave*
############################

############################
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
waitPodUp app=flannel kube-flannel
waitPodUp k8s-app=kube-dns kube-system
# kubectl delete -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
# sudo rm -f /etc/cni/net.d/10-flannel.conflist
# sudo rm -f /opt/cni/bin/flannel*
############################
}
exit $?
