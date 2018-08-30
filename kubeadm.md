# start the k8s master

`sudo kubeadm init --apiserver-advertise-address=192.169.56.3 --pod-network-cidr=10.244.0.0/16 `

# tear down the node

1.  on master:

`kubectl drain [nodename] --delete-local-data --force --ignore-daemonsets`

`kubectl delete node [nodename]`

2. on node you want to tear down

`kubeadm reset`

# join to the cluster

`kubeadm join 192.169.56.3:6443 --token [token] --discovery-token-ca-cert-hash [hash]`
