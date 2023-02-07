sudo kubeadm join 192.168.33.10:6443 --token 9c1kbz.0tri9elr8iwd17na --discovery-token-ca-cert-hash sha256:3a545a7345c0fd3834e66e8475c85fa0dab1056853ec2935d452233e8b08c5c4  --node-name=$(hostname -s)
