
# 在 k8s 以 statefulset 模式运行 rabbitmq 集群

```
git clone https://github.com/gobomb/rabbitmq-peer-discovery-k8s
cd rabbitmq-peer-discovery-k8s/examples/k8s_statefulsets

vim rabbitmq_statefulsets.yaml

127   volumeClaimTemplates:
128     - metadata:
129         name: mqclaim
130         # namespace: test-rabbitmq
131         annotations:
132           volume.beta.kubernetes.io/storage-class: "nfs-storage-provisioner"
133       spec:
134         accessModes:
135           - ReadWriteMany
136         storageClassName: "nfs-storage-provisioner" #"managed-nfs-storage"
137         resources:
138           requests:
139             storage: 1Gi

# 132/135要改成集群内部的storage-class
# kubectl get storageClass 可查看集群的storage-class

kubectl apply -f rabbitmq_ns.yaml
kubectl apply -f rabbitmq_rbac.yaml
kubectl apply -f rabbitmq_statefulsets.yaml
```

# 在 k8s 以 statefulset 模式运行 prosgresql 集群

```
git clone https://github.com/gobomb/crunchy-containers
cd crunchy-containers/examples/kube/statefulset
vim statefulset-ns.yaml
vim env.sh
# 把BUILDBASE的值改为crunchy-containers的绝对路径
# 把CCP_NAMESPACE改为statefulset-ns.yaml里指定的namespace
# 把CCP_STORAGE_CLASS改为集群内部的storage-class

./run.sh
```

# 在 k8s 以 statefulset 模式运行 redis 集群

使用这个仓库的 yaml：

https://github.com/corybuecker/redis-stateful-set

primary.yml 和 secondary.yml 里需要指定storageclass： 

```
 37   volumeClaimTemplates:
 38   - metadata:
 39       name: redis-primary-volume
 40       annotations:
 41          volume.beta.kubernetes.io/storage-class: "nfs-storage-provisioner"
 42     spec:
 43       accessModes: [ "ReadWriteOnce" ]
 44       resources:
 45         requests:
 46           storage: 5Gi
```

volume.beta.kubernetes.io/storage-class的值填该k8s集群的storageclass


```
kubectl create -f primary.yml -f secondary.yml -f sentinel.yml
```

最终是一主二从三哨兵的架构

# 在 k8s 以 statefulset 模式运行 mysql 集群

使用官网教程的方案：https://kubernetes.io/docs/tasks/run-application/run-replicated-stateful-application/

需要科学上网

```
wget https://k8s.io/examples/application/mysql/mysql-configmap.yaml

wget https://k8s.io/examples/application/mysql/mysql-services.yaml

wget https://k8s.io/examples/application/mysql/mysql-statefulset.yaml

kubectl create -f configmap.yaml

kubectl create -f services.yaml

kubectl create -f statefulset.yaml

```

同样 statefulset.yaml 需要制定storageclass

# 在 k8s 以 statefulset 模式运行 mongodb 集群

vim mongo.yaml

```
#	Copyright 2016, Google, Inc.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http:#www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
---
apiVersion: v1
kind: Service
metadata:
  name: mongo
  labels:
    name: mongo
spec:
  ports:
  - port: 27017
    targetPort: 27017
  clusterIP: None
  selector:
    role: mongo
---
apiVersion: apps/v1beta1
kind: StatefulSet
metadata:
  name: mongo
spec:
  serviceName: "mongo"
  replicas: 3
  template:
    metadata:
      labels:
        role: mongo
        environment: test
    spec:
      terminationGracePeriodSeconds: 10
      containers:
        - name: mongo
          image: mongo:3.4
          command:
            - mongod
            - "--replSet"
            - rs0
            - "--bind_ip"
            - 0.0.0.0
            - "--smallfiles"
            - "--noprealloc"
          ports:
            - containerPort: 27017
          volumeMounts:
            - name: mongo-persistent-storage
              mountPath: /data/db
        - name: mongo-sidecar
          image: cvallance/mongo-k8s-sidecar
          env:
            - name: MONGO_SIDECAR_POD_LABELS
              value: "role=mongo,environment=test"
  volumeClaimTemplates:
  - metadata:
      name: mongo-persistent-storage
      annotations:
        volume.beta.kubernetes.io/storage-class: "nfs-storage-provisioner" #这里需制定集群内的storage-class
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 2Gi
```

`kubectl apply -f mongo.yaml`

# 在 docker 跑三节点的 rabbitmq 集群

通过 docker 启动三个 rabbitmq 节点

创建 master 节点：

```
docker run --name rabbitmq-a \
    -d  -p 4369:4369 \
    -p 5671:5671 \
    -p 5672:5672 \
    -p 25672:25672 \
    -p 15672:15672 \
    -h node1 \
    -e RABBITMQ_NODENAME=rabbit \
    -e RABBITMQ_DEFAULT_USER=admin \
    -e RABBITMQ_DEFAULT_PASS=admin \
    -v /root/volume/rabbitmq/rabbitmq-a/data:/var/lib/rabbitmq \
    rabbitmq:3.6.14-management
```

将 .erlang.cookie 复制到其他节点的 data 目录下（每个节点 .erlang.cookie 必须一致）：

```
mkdir -p /root/volume/rabbitmq/rabbitmq-b/data

mkdir -p /root/volume/rabbitmq/rabbitmq-c/data

cp /root/volume/rabbitmq/rabbitmq-a/data/.erlang.cookie /root/volume/rabbitmq/rabbitmq-b/data

cp /root/volume/rabbitmq/rabbitmq-a/data/.erlang.cookie /root/volume/rabbitmq/rabbitmq-c/data

```

运行另外两个节点：

```
docker run --name rabbitmq-b \
   -d -p 4469:4369 \
   -p 5771:5671 \
    -p 5772:5672 \
     -p 26672:25672 \
     -p 16672:15672 \
     -h node2 \
     -e RABBITMQ_NODENAME=rabbit \
     -e RABBITMQ_DEFAULT_USER=admin \
     -e RABBITMQ_DEFAULT_PASS=admin \
     --link rabbitmq-a \
     -v /root/volume/rabbitmq/rabbitmq-b/data:/var/lib/rabbitmq \
     rabbitmq:3.6.14-management
```

```
docker run --name rabbitmq-c \
   -d -p 4569:4369 \
    -p 5871:5671 \
    -p 5872:5672 \
    -p 27672:25672 \
    -p 17672:15672 \
    -h node3 \
    -e RABBITMQ_NODENAME=rabbit \
    -e RABBITMQ_DEFAULT_USER=admin \
    -e RABBITMQ_DEFAULT_PASS=admin \
        --link rabbitmq-a \
    --link rabbitmq-b \
    -v /root/volume/rabbitmq/rabbitmq-c/data:/var/lib/rabbitmq \
    rabbitmq:3.6.14-management
```

使 rabbitmq-a/node1 为 master，其他两个加入 node1 集群（rabbitmq 通过主机名来互相发现）：

```
docker exec -it rabbitmq-b bash
rabbitmqctl stop_app
rabbitmqctl join_cluster rabbit@node1
rabbitmqctl start_app
exit

docker exec -it rabbitmq-c bash
rabbitmqctl stop_app
rabbitmqctl join_cluster rabbit@node1
rabbitmqctl start_app
exit
```

`rabbitmqctl cluster_status` 可以查看集群状态：

```
# rabbitmqctl cluster_status
Cluster status of node rabbit@node2
[{nodes,[{disc,[rabbit@node1,rabbit@node2]}]},
 {running_nodes,[rabbit@node1,rabbit@node2]},
 {cluster_name,<<"rabbit@node1">>},
 {partitions,[]},
 {alarms,[{rabbit@node1,[]},{rabbit@node2,[]}]}]
 ```
