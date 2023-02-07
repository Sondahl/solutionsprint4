#!/bin/bash

echo "============================================="
echo "          Iniciando script commom"
echo "============================================="

echo "============================================="
echo "           Configurando profiles"
echo "============================================="
echo "KUBELET_EXTRA_ARGS=\"--node-ip=$nodeip --hostname-override=$(hostname -s)\"" > /etc/sysconfig/kubelet
systemctl daemon-reload 
systemctl restart kubelet.service 

cp -f /vagrant/scripts/kube.functions /etc/bash_completion.d/
chmod 644 /etc/bash_completion.d/kube.functions

for i in /root /home/vagrant ; do
  cat <<EOF >> $i/.bashrc
## Kubernetes ##
alias kwatch="watch kubectl get nodes,services,pods --all-namespaces --show-labels"
alias k=kubectl
complete -o default -F __start_kubectl k
export KUBE_PROXY_MODE=ipvs
EOF
  echo "## SSH aliases ##" >> $i/.bashrc
  echo "alias master=\"ssh master\"" >> $i/.bashrc
  for (( c=1; c<=$workers; c++ )) ; do
    echo "alias node-$c=\"ssh node-$c\"" >> $i/.bashrc
  done
done
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> /root/.bashrc

echo "============================================="
echo "         Configurando /etc/hosts"
echo "============================================="
echo "$ipbase.$firstip master master.local master-node master-node.local" >> /etc/hosts
for (( c=1; c<=$workers; c++ )) ; do
  ip=$(($firstip+$c))
  echo "$ipbase.$ip node-$c node-$c.local worker-node-$c worker-node-$c.local" >> /etc/hosts
done

echo "============================================="
echo "         Finalizando script commom"
echo "============================================="
