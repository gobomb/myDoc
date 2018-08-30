# start the k8s master

`sudo kubeadm init --apiserver-advertise-address=192.169.56.3 --pod-network-cidr=10.244.0.0/16 `

## set the flannel network

`sysctl net.bridge.bridge-nf-call-iptables=1`

`kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.10.0/Documentation/kube-flannel.yml`

# tear down the cluster

1.  on master:

`kubectl drain [nodename] --delete-local-data --force --ignore-daemonsets`

`kubectl delete node [nodename]`

2. on node you want to tear down

`kubeadm reset`

3. after all node are removed, run this on master too

`kubeadm reset`

# join to the cluster

`kubeadm join 192.169.56.3:6443 --token [token] --discovery-token-ca-cert-hash [hash]`
