#!/bin/bash

cat << EOF | sudo tee /tmp/startup_script.sh
#!/bin/bash
sudo modprobe dummy
for i in {100..120} ; do
  # sudo ip addr add 192.168.33.\${i}/24 brd + dev eth1 label eth1:\${i}
  sudo ip addr add 192.168.33.\${i}/24 brd + dev eth1
done
EOF
sudo chmod 755 /tmp/startup_script.sh

cat << EOF | sudo tee /etc/systemd/system/run-at-startup.service
[Unit]
Description=Run script at startup after network becomes reachable
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
RemainAfterExit=yes
ExecStart=/tmp/startup_script.sh
TimeoutStartSec=0

[Install]
WantedBy=default.target
EOF

cat << EOF | sudo tee /etc/sysconfig/kubelet
KUBELET_EXTRA_ARGS=--node-ip=192.168.33.10
EOF
sudo sed -i '/RestartSec/ a EnvironmentFile=-/etc/sysconfig/kubelet' /usr/lib/systemd/system/kubelet.service
sudo systemctl daemon-reload 
sudo systemctl enable run-at-startup.service
sudo systemctl start run-at-startup.service
sudo systemctl restart kubelet

getPodUp(){
  while [ $(kubectl get pods -l $1 -n $2 -o jsonpath='{ .items[].status.phase }' 2>/dev/null | wc -m) = '0' ]
  do 
    { printf .; sleep 1; }
  done
}
getPodPending(){
  while [ $(kubectl get pods -l $1 -n $2 -o jsonpath='{ .items[].status.phase }' 2>/dev/null) != 'Pending' ]
  do 
    { printf .; sleep 1; }
  done
}
getPodRunning(){
  while [ $(kubectl get pods -l $1 -n $2 -o jsonpath='{ .items[].status.phase }' 2>/dev/null) != 'Running' ]
  do 
    { printf .; sleep 1; }
  done
}

# sudo kubeadm init --apiserver-advertise-address="192.168.33.10"\
#  --pod-network-cidr="10.244.0.0/16"

# sudo kubeadm init --apiserver-advertise-address="192.168.33.10"\
#  --control-plane-endpoint="192.168.33.10" --pod-network-cidr="10.244.0.0/16"\
#  --service-cidr="10.96.0.0/12" --service-dns-domain="cluster.local" --upload-certs

sudo kubeadm init --apiserver-advertise-address="192.168.33.10"\
 --apiserver-cert-extra-sans="192.168.33.10"\
 --control-plane-endpoint="192.168.33.10"\
 --pod-network-cidr="10.244.0.0/16"\
 --node-name master-node\
 --upload-certs

mkdir -p /home/vagrant/.kube
sudo cp -f /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown -R vagrant:vagrant /home/vagrant/.kube
echo "alias k=kubectl" >> /home/vagrant/.bashrc
echo "alias kwatch=\"watch kubectl get nodes,services,pods --all-namespaces -o wide --show-labels\"" >> /home/vagrant/.bashrc
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" | sudo tee -a /root/.bashrc

getPodUp k8s-app=kube-proxy kube-system
getPodRunning k8s-app=kube-proxy kube-system


############################
# kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml
# getPodUp name=weave-net kube-system
# getPodRunning name=weave-net kube-system
# getPodUp k8s-app=kube-dns kube-system
# getPodRunning k8s-app=kube-dns kube-system
# sudo /usr/local/bin/allIntFW.sh
# kubectl delete -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml
# sudo rm -f /etc/cni/net.d/10-weave.conflist
# sudo rm -f /opt/cni/bin/weave*
############################

############################
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
getPodUp app=flannel kube-flannel
getPodRunning app=flannel kube-flannel
getPodUp k8s-app=kube-dns kube-system
getPodRunning k8s-app=kube-dns kube-system
# kubectl delete -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
# sudo rm -f /etc/cni/net.d/10-flannel.conflist
# sudo rm -f /opt/cni/bin/flannel*
############################

# kubectl delete pods -l k8s-app=kube-dns -n kube-system
# kubectl get pods -l k8s-app=kube-dns -n kube-system -o jsonpath='{ .items[].status.phase }'

############################
# kubectl get configmap kube-proxy -n kube-system -o yaml |\
#  sed -e "s/strictARP: false/strictARP: true/" |\
#  sed -e "s/mode: \"\"/mode: \"ipvs\"/" |\
#  kubectl diff -f - -n kube-system
#
# kubectl get configmap kube-proxy -n kube-system -o yaml |\
#  sed -e "s/strictARP: false/strictARP: true/" |\
#  sed -e "s/mode: \"\"/mode: \"ipvs\"/" |\
#  kubectl apply -f - -n kube-system
#
# kubectl delete pods -l k8s-app=kube-proxy -n kube-system
# getPodUp k8s-app=kube-proxy kube-system
# getPodRunning k8s-app=kube-proxy kube-system
#
# kubectl taint nodes --all node-role.kubernetes.io/control-plane-
# kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml
# getPodUp component=controller metallb-system
# getPodRunning component=controller metallb-system
# kubectl apply -f /vagrant/config/ipaddresspool_simple.yaml
# kubectl apply -f /vagrant/config/simple_pool_adv_l2.yaml
# kubectl apply -f /vagrant/config/deployment_l2.yaml
# getPodUp app=nginx default
# getPodRunning app=nginx default
#
# kubectl apply -f https://raw.githubusercontent.com/scriptcamp/kubeadm-scripts/main/manifests/metrics-server.yaml
# getPodUp k8s-app=metrics-server kube-system
# getPodRunning k8s-app=metrics-server kube-system
############################

############################
# curl -sL https://github.com/operator-framework/operator-lifecycle-manager/releases/download/v0.23.1/install.sh | bash -s v0.23.1
# getPodUp app=catalog-operator olm
# getPodRunning app=catalog-operator olm
# getPodUp app=packageserver olm
# getPodRunning app=packageserver olm
# kubectl create -f https://operatorhub.io/install/metallb-operator.yaml
# kubectl get csv -n operators
# Pesquisar comando kubectl wait. Exemple:
# kubectl create -f "${url}/crds.yaml"
# kubectl wait --for=condition=Established -f "${url}/crds.yaml"
# kubectl create -f "${url}/olm.yaml"
############################

############################
# kubectl apply -f https://github.com/weaveworks/scope/releases/download/v1.13.2/k8s-scope.yaml
# getPodUp app=weave-scope weave
# getPodRunning app=weave-scope weave
# kubectl patch svc weave-scope-app -n weave -p '{"spec": {"type": "LoadBalancer"}}'
############################

############################
# wget https://raw.githubusercontent.com/tonanuvem/k8s-exemplos/master/dashboard_loadbalancer.sh
# sh dashboard_loadbalancer.sh
############################

############################
# wget https://raw.githubusercontent.com/tonanuvem/k8s-exemplos/master/istio_run_loadbalancer.sh
# sh istio_run_loadbalancer.sh
# cd istio-1.16.1
# kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
# kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml && kubectl get service istio-ingressgateway -n istio-system
# kubectl apply -f samples/bookinfo/networking/destination-rule-all.yaml
# kubectl apply -f samples/bookinfo/networking/virtual-service-reviews-test-v2.yaml
# kubectl apply -f samples/bookinfo/networking/virtual-service-reviews-80-20.yaml
# kubectl apply -f samples/bookinfo/networking/virtual-service-reviews-50-v3.yaml
# cd 
############################

############################
# git clone https://github.com/microservices-demo/microservices-demo.git
############################

exit 0