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
. $HOME/.bashrc
sudo cp -f /vagrant/scripts/kube.functions /etc/bash_completion.d/
. /etc/bash_completion.d/kube.functions
mkdir -p /home/vagrant/.kube
echo "KUBELET_EXTRA_ARGS=\"--node-ip=$nodeip\"" | sudo tee /etc/sysconfig/kubelet

sudo kubeadm join 192.168.33.10:6443 --token v8jyno.rpunnjwoabc0a8d4 --discovery-token-ca-cert-hash sha256:68817bc1cecf6af4b7f28a5bbb68711d68b237c010bd7754e8470f2dc6fb79b7 
cp -f /vagrant/config/admin.conf /home/vagrant/.kube/config
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" | sudo tee -a /root/.bashrc
sudo chown -R vagrant:vagrant /home/vagrant/.kube
kubectl label node $(hostname -s) node-role.kubernetes.io/worker=worker
}
exit $?
