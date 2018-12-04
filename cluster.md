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

# 在 k8s 以 statefulset 模式运行 redis 集群

使用这个仓库的 yaml：

https://github.com/corybuecker/redis-stateful-set

primary.yml 和 secondary.yml 里需要指定storageclass： `spec.volumeClaimTemplates.metadata.annotations: volume.beta.kubernetes.io/storage-class: "managed-nfs-storage"`

managed-nfs-storage 替换为该k8s集群的storageclass


```
kubectl create -f primary.yml -f secondary.yml -f sentinel.yml
```

最终是一主二从三哨兵的架构

# 在 k8s 以 statefulset 模式运行 mysql 集群

使用官网教程的方案：https://kubernetes.io/docs/tasks/run-application/run-replicated-stateful-application/

需要科学上网

```
kubectl create -f https://k8s.io/examples/application/mysql/mysql-configmap.yaml

kubectl create -f https://k8s.io/examples/application/mysql/mysql-services.yaml

kubectl create -f https://k8s.io/examples/application/mysql/mysql-statefulset.yaml
```
