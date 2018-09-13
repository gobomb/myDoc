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

# issue

## time zone error when the node join to the cluster

When join to the cluster, we get a error like this:

```
...
[discovery] Failed to request cluster info, will try again: [Get https://192.169.56.3:6443/api/v1/namespaces/kube-public/configmaps/cluster-info: x509: certificate has expired or is not yet valid]
```

The reason is that the time of node and master is different. We should synchronize the time and time zone, run the same command:

```
tzselect

sudo cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
```

And we can run `date` to see the time.
