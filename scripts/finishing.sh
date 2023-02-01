#!/bin/bash

echo "============================================="
echo "          Iniciando script final"
echo "============================================="
echo "============================================="
echo "           Configurando variables"
echo "============================================="
lbrange=($lbrange)
source /etc/bash_completion.d/kube.functions



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
# wget https://raw.githubusercontent.com/tonanuvem/k8s-exemplos/master/istio_run_loadbalancer.sh
# sh istio_run_loadbalancer.sh
# # cd istio-1.16.1
# kubectl apply -f istio-1.16.1/samples/bookinfo/platform/kube/bookinfo.yaml
# kubectl apply -f istio-1.16.1/samples/bookinfo/networking/bookinfo-gateway.yaml 
# kubectl get service istio-ingressgateway -n istio-system
# kubectl apply -f istio-1.16.1/samples/bookinfo/networking/destination-rule-all.yaml
# kubectl apply -f istio-1.16.1/samples/bookinfo/networking/virtual-service-reviews-test-v2.yaml
# kubectl apply -f istio-1.16.1/samples/bookinfo/networking/virtual-service-reviews-80-20.yaml
# kubectl apply -f istio-1.16.1/samples/bookinfo/networking/virtual-service-reviews-50-v3.yaml
# cd 
############################

# ############################
# git clone https://github.com/microservices-demo/microservices-demo.git
############################

# kubectl delete pods -l k8s-app=kube-dns -n kube-system
# kubectl get pods -l k8s-app=kube-dns -n kube-system -o jsonpath='{ .items[].status.phase }'
