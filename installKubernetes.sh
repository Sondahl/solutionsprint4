## Run on Master Node
# hostnamectl set-hostname kubemaster-node
## Run on Worker Node-1
# hostnamectl set-hostname kubeworker-node-1
## Run on Worker Node-2
# hostnamectl set-hostname kubeworker-node-2

cat >> /etc/hosts << EOF
192.168.15.110 kubemaster-node
192.168.15.111 node-1 kubeworker-node-1
192.168.15.112 node-2 kubeworker-node-2
EOF

setenforce 0
sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
swapoff -a
sed -i '/swap/ s/^/#/' /etc/fstab

timedatectl set-timezone America/Sao_Paulo
sed -i '1 s/^/server a.st1.ntp.br iburst\nserver b.st1.ntp.br iburst\nserver c.st1.ntp.br iburst\nserver d.st1.ntp.br iburst\nserver a.ntp.br iburst\nserver b.ntp.br iburst\nserver c.ntp.br iburst\nserver gps.ntp.br iburst\n/' /etc/chrony.conf
systemctl restart chronyd

firewall-cmd --set-default-zone=public
firewall-cmd --permanent --add-service=dns
firewall-cmd --permanent --add-service=dhcp
firewall-cmd --permanent --add-service=dhcpv6-client
firewall-cmd --permanent --add-service=ssh
firewall-cmd --permanent --add-port=2379-2380/tcp
firewall-cmd --permanent --add-port=6443/tcp
firewall-cmd --permanent --add-port=6783/tcp
firewall-cmd --permanent --add-port=6783/udp
firewall-cmd --permanent --add-port=6784/udp
firewall-cmd --permanent --add-port=10250/tcp
firewall-cmd --permanent --add-port=10251/tcp
firewall-cmd --permanent --add-port=10252/tcp
firewall-cmd --permanent --add-port=10255/tcp
firewall-cmd --permanent --add-port=30000-32767/tcp
firewall-cmd --permanent --add-port=7946/tcp
firewall-cmd --permanent --add-port=7946/udp
firewall-cmd --reload
firewall-cmd --list-all

cat > /etc/modules-load.d/k8s.conf << EOF
br_netfilter
conntrack
overlay
EOF
modprobe br_netfilter
modprobe ip_conntrack
modprobe ip_conntrack

cat > /etc/sysctl.d/99-k8s-iptables.conf << EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-iptables = 1 
EOF
cat > /etc/sysctl.d/99-k8s-forward.conf << EOF
net.ipv4.ip_forward = 1
EOF
cat > /etc/sysctl.d/99-k8s-conntrack.conf << EOF
net.netfilter.nf_conntrack_max = 1000000
EOF
sysctl --system

yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

cat > /etc/yum.repos.d/kubernetes.repo << EOF
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

yum install -y https://packages.endpointdev.com/rhel/7/os/x86_64/endpoint-repo.x86_64.rpm
yum update -y git
cp /usr/share/doc/git-2.38.1/contrib/completion/git-completion.bash /etc/bash_completion.d/
cp /usr/share/doc/git-2.38.1/contrib/completion/git-prompt.sh /etc/bash_completion.d/
echo "export GIT_PS1_SHOWDIRTYSTATE=1" >> /etc/bashrc
echo "export PS1=\"[\u@\h \W \$(__git_ps1 \" (%s)\")]\\\\$ \"" >> /etc/bashrc
yum install -y golang cri ebtables ipset docker-ce containerd.io kubelet kubeadm kubectl --disableexcludes=kubernetes 

systemctl enable --now docker
systemctl start containerd
systemctl enable --now containerd
systemctl start containerd
systemctl enable --now kubelet
systemctl start kubelet

echo '{
  "exec-opts": ["native.cgroupdriver=systemd"]
}' > /etc/docker/daemon.json

mv -f /etc/containerd/config.toml /etc/containerd/config.toml_orig
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart docker
systemctl restart containerd
systemctl restart kubelet

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl-convert"
curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl-convert.sha256"
echo "$(cat kubectl-convert.sha256) kubectl-convert" | sha256sum --check
install -o root -g root -m 0755 kubectl-convert /usr/local/bin/kubectl-convert

kubectl completion bash | tee /etc/bash_completion.d/kubectl.bash > /dev/null
kubeadm completion bash | tee /etc/bash_completion.d/kubeadm.bash > /dev/null

kubeadm init --apiserver-advertise-address="192.168.15.110" --pod-network-cidr="10.244.0.0/16"
# kubeadm init --pod-network-cidr="10.244.0.0/16"

####################################################################
# kubeadm join 192.168.15.110:6443 --token c7rvi5.4jk4qbprdynfrjw2 \
#         --discovery-token-ca-cert-hash sha256:dd4fa74eb431fa2a6792572a61542445c902f7044d1f79ab65110dd6935f6061
####################################################################
echo "Run command above to join new nodes:"
echo ""
kubeadm token create --print-join-command

if [ $UID -eq 0 ] ; then
  echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> $HOME/.bashrc
  export KUBECONFIG=/etc/kubernetes/admin.conf
else
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
fi
echo 'alias k=kubectl' >> $HOME/.bashrc
echo 'alias kwatch="watch kubectl get nodes,services,pods --all-namespaces -o wide"' >> $HOME/.bashrc
echo 'complete -o default -F __start_kubectl k' >> $HOME/.bashrc
echo "export PATH=\$PATH:." >> $HOME/.bashrc
source $HOME/.bashrc

kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml

kubectl get configmap kube-proxy -n kube-system -o yaml | \
sed -e "s/strictARP: false/strictARP: true/" | \
kubectl diff -f - -n kube-system

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml

cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.15.10-192.168.15.20
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: empty
  namespace: metallb-system
EOF

kubectl apply -f https://github.com/weaveworks/scope/releases/download/v1.13.2/k8s-scope.yaml && kubectl patch svc weave-scope-app -n weave -p '{"spec": {"type": "LoadBalancer"}}'

wget https://raw.githubusercontent.com/tonanuvem/k8s-exemplos/master/dashboard_loadbalancer.sh
sh dashboard_loadbalancer.sh

wget https://raw.githubusercontent.com/tonanuvem/k8s-exemplos/master/istio_run_loadbalancer.sh
sh istio_run_loadbalancer.sh
cd istio-1.16.1
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml && kubectl get service istio-ingressgateway -n istio-system
kubectl apply -f samples/bookinfo/networking/destination-rule-all.yaml
kubectl apply -f samples/bookinfo/networking/virtual-service-reviews-test-v2.yaml
kubectl apply -f samples/bookinfo/networking/virtual-service-reviews-80-20.yaml
kubectl apply -f samples/bookinfo/networking/virtual-service-reviews-50-v3.yaml
cd 
git clone https://github.com/microservices-demo/microservices-demo.git

exit 0