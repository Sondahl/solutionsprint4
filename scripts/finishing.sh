#!/bin/bash

echo "============================================="
echo "          Iniciando script final"
echo "============================================="
source /etc/bash_completion.d/kube.functions

echo "============================================="
echo "           Instalando MealLB"
echo "============================================="

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml
waitPodUp component=controller metallb-system
waitPodUp app=metallb metallb-system

echo "============================================="
echo "         Aplicando MetalLB Polls"
echo "============================================="
waitPodUp k8s-app=kube-proxy kube-system
waitPodUp component=controller metallb-system
waitPodUp component=speaker metallb-system
for conf in $(find /vagrant/config/ -name pool*) ; do
  echo "Aplicando kubectl apply -f $conf"
  pool=$(grep hostname $conf | awk '{ print $2 }')
  getPoll="kubectl get -n metallb-system ipaddresspools.metallb.io pool-$pool" 
  count=0
  while [[ $($getPoll 2>/dev/null | wc -m) = '0' ]] && [[ $count -lt 5 ]]; do 
    printf .
    bash -c "kubectl apply -f $conf >/dev/null 2>&1"
    sleep 1
    ((count++))
  done
  if [[ $($getPoll 2>/dev/null | wc -m) = '0' ]] ; then
    echo " Pool $pool: Erro"
    $getPoll
  else
    echo " Poll $pool: Aplicado"
    $getPoll
    rm -f $conf
  fi
done
waitPodUp app=metallb metallb-system

# echo "============================================="
# echo "          Instalando o dashboard"
# echo "============================================="
# wget -nv https://raw.githubusercontent.com/tonanuvem/k8s-exemplos/master/dashboard_loadbalancer.sh
# sh dashboard_loadbalancer.sh
# waitPodUp k8s-app=kubernetes-dashboard kubernetes-dashboard

# echo "============================================="
# echo "          Instalando o WaveScope"
# echo "============================================="
# kubectl apply -f https://github.com/weaveworks/scope/releases/download/v1.13.2/k8s-scope.yaml
# waitPodUp app=weave-scope weave
# kubectl patch svc weave-scope-app -n weave -p '{"spec": {"type": "LoadBalancer"}}'
# waitPodUp app=weave-scope weave

# echo "============================================="
# echo "          Instalando o Metrics pod"
# echo "============================================="
# kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
# waitPodUp k8s-app=metrics-server kube-system

# echo "============================================="
# echo "      Instalando o dashboard-opertor"
# echo "============================================="
# ############################
# curl -sL https://github.com/operator-framework/operator-lifecycle-manager/releases/download/v0.23.1/install.sh | bash -s v0.23.1
# waitPodUp app=catalog-operator olm
# getPodUp app=packageserver olm
# kubectl create -f https://operatorhub.io/install/metallb-operator.yaml
############################

# echo "============================================="
# echo "             Instalando o istio"
# echo "============================================="
# wget -nv https://raw.githubusercontent.com/tonanuvem/k8s-exemplos/master/istio_run_loadbalancer.sh -P $HOME
# sh $HOME/istio_run_loadbalancer.sh
# PASTA=$(ls $HOME | grep istio-)
# cd $PASTA
# kubectl apply -f ./samples/bookinfo/platform/kube/bookinfo.yaml
# kubectl apply -f ./samples/bookinfo/networking/bookinfo-gateway.yaml 
# kubectl apply -f ./samples/bookinfo/networking/destination-rule-all.yaml
# # kubectl apply -f ./samples/bookinfo/networking/virtual-service-reviews-test-v2.yaml
# # kubectl apply -f ./samples/bookinfo/networking/virtual-service-reviews-80-20.yaml
# # kubectl apply -f ./samples/bookinfo/networking/virtual-service-reviews-50-v3.yaml
# cd

# ############################
# git clone https://github.com/microservices-demo/microservices-demo.git
############################

echo "============================================="
echo "         Finalizando script final"
echo "============================================="