#!/bin/bash

sha=$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //')
token=$(kubeadm token list | awk 'NR>1{print $1}')
echo "sudo kubeadm join {$1}:6443 --token $token --discovery-token-ca-cert-hash sha256:${sha}"
