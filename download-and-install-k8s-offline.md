# 下载和离线安装 kubernetes 1.11.3

# 安装的机器规格

（待补充）

```
1 master
3 node
1 nfs-sever&registry
1 gitlab
1 jenkins
```

# 下载过程


## 前提

1. Linux 环境

2. 能够科学上网

3. 已经安装了 docker、wget、tar、curl 等工具

## 下载 docker 二进制

```

wget https://download.docker.com/linux/static/stable/x86_64/docker-17.12.1-ce.tgz

wget https://raw.githubusercontent.com/moby/moby/master/contrib/init/systemd/docker.service

wget https://raw.githubusercontent.com/moby/moby/master/contrib/init/systemd/docker.socket

```

## 下载 kubeadm、kubelet、kubectl 二进制

```

#RELEASE="$(curl -sSL https://dl.k8s.io/release/stable.txt)"

RELEASE=v1.11.3

curl -L --remote-name-all https://storage.googleapis.com/kubernetes-release/release/${RELEASE}/bin/linux/amd64/{kubeadm,kubelet,kubectl,crictl}

curl -sSL "https://raw.githubusercontent.com/kubernetes/kubernetes/${RELEASE}/build/debs/kubelet.service">kubelet.service

curl -sSL "https://raw.githubusercontent.com/kubernetes/kubernetes/${RELEASE}/build/debs/10-kubeadm.conf">10-kubeadm.conf

```

## 下载网络相关二进制

```

CNI_VERSION="v0.6.0"

wget "https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-amd64-${CNI_VERSION}.tgz"

```

## 下载 flannel 和 nfs 相关 yaml

```

wget https://raw.githubusercontent.com/coreos/flannel/v0.10.0/Documentation/kube-flannel.yml

wget https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/nfs-client/deploy/rbac.yaml

wget https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/nfs-client/deploy/deployment.yaml

wget https://raw.githubusercontent.com/kubernetes-incubator/external-storage/master/nfs-client/deploy/class.yaml

```

## 下载相关镜像

```

# 一键下载打包所有需要的镜像，包括 kubeadm 需要的镜像、nfs-server、rigistry

wget https://raw.githubusercontent.com/gobomb/myDoc/master/save-images.sh&&chmod +x save-images.sh&&./save-images.sh

```

## 清单

```

# 每台机器都要：

docker-17.12.1-ce.tgz

docker.service

docker.socket

# master 和 node 需要：

kubeadm

kubelet

kubelet.service

crictl

10-kubeadm.conf

cni-plugins-amd64-v0.6.0.tgz

# master 需要：

kubectl

kube-flannel.yml

rbac.yaml

deployment.yaml

class.yaml

# 镜像

saved-images.tar.gz

## master 节点：

k8s.gcr.io/kube-proxy-amd64:v1.11.3

k8s.gcr.io/kube-scheduler-amd64:v1.11.3

k8s.gcr.io/kube-apiserver-amd64:v1.11.3

k8s.gcr.io/kube-controller-manager-amd64:v1.11.3

k8s.gcr.io/coredns:1.1.3

quay.io/coreos/flannel:v0.10.0-amd64

k8s.gcr.io/etcd-amd64:3.2.18

k8s.gcr.io/pause:3.1

## node 节点：

k8s.gcr.io/pause:3.1

k8s.gcr.io/kube-proxy-amd64:v1.11.3

quay.io/coreos/flannel:v0.10.0-amd64

quay.io/external_storage/nfs-client-provisioner:latest

## 存储和镜像仓库节点：

fuzzle/docker-nfs-server:latest

registry:latest

```

# 安装过程

（记录的大致过程，有些细节还在完善）

## 安装 docker

`tar -xzvf docker-17.12.1-ce.tgz`

`chmod +x docker/*`

`cp docker/* /usr/bin/`

`cp docker.service /lib/systemd/system/docker.service`

`cp docker.socket /lib/systemd/system/docker.socket`

`groupadd docker`

`systemctl enable docker && systemctl start docker`

## 安装 kubeadm,kubelet,kubectl

`chmod +x kubeadm&&chmod +x kubelet&&chmod +x kubectl&&chmod +x crictl`

`cp kubeadm /usr/bin/kubeadm && cp kubelet /usr/bin/kubelet && cp kubectl /usr/bin/kubectl && cp crictl /usr/bin/crictl`

`cp kubelet.service /etc/systemd/system/kubelet.service`

`mkdir -p /etc/systemd/system/kubelet.service.d`

`cp 10-kubeadm.conf /etc/systemd/system/kubelet.service.d/10-kubeadm.conf`

`systemctl enable kubelet && systemctl start kubelet`

## 导入相关容器

`tar xzvf saved-images.tar.gz`

```

docker load < saved-images/k8s.gcr.io_kube-proxy-amd64:v1.11.3.tar

...

```

## 初始化 master

```

sudo kubeadm init --apiserver-advertise-address=10.10.12.27 --pod-network-cidr=10.244.0.0/16 --kubernetes-version v1.11.3

```

```

mkdir -p $HOME/.kube

sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config

sudo chown $(id -u):$(id -g) $HOME/.kube/config

# 记录下 kubeadm init 的输出：

kubeadm join --token <token> <master-ip>:<master-port> --discovery-token-ca-cert-hash sha256:<hash>

```

## 安装网络插件 flannel

```

mkdir -p /opt/cni/bin

tar xzf cni-plugins-amd64-v0.6.0.tgz -C /opt/cni/bin

chmod +x /opt/cni/bin/*

kubectl apply -f kube-flannel.yml

```

## 安装 nfs-server 和 registry

```

docker run -d --privileged --restart=always \

-v /tmp:/nfs \

-e NFS_EXPORT_DIR_1=/nfs \

-e NFS_EXPORT_DOMAIN_1=\* \

-e NFS_EXPORT_OPTIONS_1=insecure,rw,no_root_squash,sync,no_subtree_check \

-p 111:111 -p 111:111/udp \

-p 2049:2049 -p 2049:2049/udp \

-p 32765:32765 -p 32765:32765/udp \

-p 32766:32766 -p 32766:32766/udp \

-p 32767:32767 -p 32767:32767/udp \

--name nfs-server\

fuzzle/docker-nfs-server:latest

docker run -d --name registry -p 5000:5000 --restart -v /data/registry:/tmp/registry always registry

```

## 安装 nfs-client-provisioner

deployment.yaml 里，修改30、32、36、37行：

```

26 env:

27 - name: PROVISIONER_NAME

28 value: mypv

29 - name: NFS_SERVER

30 value: nfs-sever地址

31 - name: NFS_PATH

32 value: /nfs

33 volumes:

34 - name: nfs-client-root

35 nfs:

36 server: nfs-sever地址

37 path: /nfs

```

`kubectl apply -f rbac.yaml deployment.yaml class.yaml`

## 初始化 node

```

kubeadm join --token <token> <master-ip>:<master-port> --discovery-token-ca-cert-hash sha256:<hash>

``` 

<hash> 到master上 `openssl x509 -in /etc/kubernetes/pki/ca.crt -noout -pubkey | openssl rsa -pubin -outform DER 2>/dev/null | sha256sum | cut -d' ' -f1`
