#!/bin/bash
version=18.03
# must disable swap
check_swap(){
    m=$(free -m|grep "Swap" | awk '{print $2}')
    if [[ $a -ne 0 ]] ; then
	    echo "please vim /etc/fs to disable swap "
	    exit 0
    fi
}

command_exists () {
    type "$1" &> /dev/null ;
}

# install docker
install() {
    VERSION=$version
    sudo apt-get install -y apt-transport-https curl
    curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | sudo apt-key add -
    sudo tee /etc/apt/sources.list.d/kubernetes.list <<-'EOF'
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF

    curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
    sudo mkdir -p /etc/docker
    sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://9t61buw6.mirror.aliyuncs.com"]
}
EOF
    sudo systemctl daemon-reload
    sudo systemctl restart docker

    sudo apt-get update
    sudo apt-get install -y kubelet kubeadm kubectl


    # pull images !

    kubeadm config images list |sed -e 's/^/docker pull /g' -e 's#k8s.gcr.io#docker.io/mirrorgooglecontainers#g' |sh -x
    docker images |grep mirrorgooglecontainers |awk '{print "docker tag ",$1":"$2,$1":"$2}' |sed -e 's#mirrorgooglecontainers#k8s.gcr.io#2' |sh -x
    docker images |grep mirrorgooglecontainers |awk '{print "docker rmi ", $1":"$2}' |sh -x

    docker pull coredns/coredns:1.2.6
    docker tag coredns/coredns:1.2.6 k8s.gcr.io/coredns:1.2.6
    docker rmi coredns/coredns:1.2.6

    # final
    docker pull  daocloud.io/a735416909/testbuild:master
    docker tag daocloud.io/a735416909/testbuild:master quay.io/coreos/flannel:v0.11.0-amd64
    docker rmi daocloud.io/a735416909/testbuild:master
}


init_master(){

    sudo kubeadm init --pod-network-cidr=172.168.10.0/24 --kubernetes-version=v1.13.4 --ignore-preflight-errors=NumCPU
    sudo mkdir -p $HOME/.kube/
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    sudo kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
    kubectl get nodes
}





check_swap
install_docker

if [[ $1 eq "master" ]] ; then
    init_master
fi



