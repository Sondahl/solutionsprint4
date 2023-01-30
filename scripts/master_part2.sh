#!/bin/bash

# kubectl delete pods -l k8s-app=kube-dns -n kube-system
# kubectl get pods -l k8s-app=kube-dns -n kube-system -o jsonpath='{ .items[].status.phase }'

############################
# echo "OPTS=\"${lbrange[0]} ${lbrange[1]} $dev\"" | sudo tee /etc/sysconfig/metalLBVips
# sudo cp -f /vagrant/scripts/metalLBVips /usr/local/bin/
# sudo chmod 755 /usr/local/bin/metalLBVips
# sudo cp -f /vagrant/config/metalLBVips.service /etc/systemd/system/
# sudo systemctl daemon-reload 
# sudo systemctl enable metalLBVips.service
# sudo systemctl start metalLBVips.service
#
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