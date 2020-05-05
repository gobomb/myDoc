# docker document note

## The underlying technology

### Namespaces

Docker uses a technology called namespaces to provide the isolated workspace called the container.

These namespaces provide a layer of isolation. Each aspect of a container runs in a separate namespace and its access is limited to that namespace.

5 namespace docker engine uses： pid、net、ipc、uts、mnt

### Control groups

Docker Engine on Linux also relies on another technology called control groups (cgroups). A cgroup limits an application to a specific set of resources. Control groups allow Docker Engine to share available hardware resources to containers and optionally enforce limits and constraints.

### Union file systems

Union file systems, or UnionFS, are file systems that operate by creating layers, making them very lightweight and fast. Docker Engine uses UnionFS to provide the building blocks for containers. 




# docker 设置

## dockerd 暴露出端口给其他主机的 docker 命令行程序调用（不安全，慎用）

dockerd 默认的进程间通信方式是 sock 文件，一般只能本机读取。

修改 docker.service 文件，使之读取环境变量配置，使用 $DOCKER_OPTS 参数：

`vim /lib/systemd/system/docker.service`

```
...
EnvironmentFile=-/etc/default/docker
ExecStart=/usr/bin/dockerd -H fd:// $DOCKER_OPTS
...
```

(`-`代表 ignore error)


`vim /etc/default/docker`

```
DOCKER_OPTS="-H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock"
```

重启 dockerd：

```
sudo systemctl   daemon-reload
systemctl restart docker
```

在另一台主机：

```
docker -H [dockerd ip]:2375 ps
```



## docker daemon 重启但容器不重启

1. `vim /etc/docker/daemon.json`

    ```
    {
    ...
          "live-restore": true,
    ...
    }
    ```
    
2. `vim /usr/lib/systemd/system/docker.service`
  
    ```
    ...
    # kill only the docker process, not all processes in the cgroup
    KillMode=process
    ...
    ```
    
## 更新已运行的容器使之自动重启

`docker update --restart=always <CONTAINER ID>`

## 给 docker daemon 设置代理

https://github.com/gobomb/toolbox/blob/master/docker/docker.md

`vim /lib/systemd/system/docker.service.d/http-proxy.conf`(CentOS 下是 /etc/...; Ubuntu 下是 /lib/...)

```
[Service]
Environment="HTTP_PROXY=0.0.0.0:5679" "HTTPS_PROXY=0.0.0.0:5679" "NO_PROXY=localhost,127.0.0.1"
```

`systemctl daemon-reload`

`systemctl restart docker`

## docker 使用私有 registry

`vim /etc/docker/daemon.json`

```
{
  "insecure-registries": [
    "your.registry.ip"
  ]
}
```

`systemctl restart docker`

## 使当前用户加入 docker 用户组

`sudo usermod -aG docker thisuser`

`sudo systemctl restart docker`

如果报错：`Got permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: Get http://%2Fvar%2Frun%2Fdocker.sock/v1.35/info: dial unix /var/run/docker.sock: connect: permission denied`

则修改 docker.sock 权限：

`sudo chmod a+rw /var/run/docker.sock`

## centos 安装 docker

```
 wget  https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
 mv docker-ce.repo  /etc/yum.repos.d/
 yum install -y docker-ce
 systemctl  daemon-reload
 systemctl  start docker  
```
### centos 卸载 docker

```
$ sudo yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine
 ```


# 问题

## 自行安装 docker.service 遇到的 `systemctl start docker`失败的问题

系统：`ubuntu 1604`

复制 https://github.com/moby/moby/tree/master/contrib/init/systemd 中的`docker.service`和`docker.socket`到`/lib/systemd/system/`下，执行`sudo systemctl daemon-reload`，`systemctl start docker`无法启动 docker daemon。

`systemctl status docker.service`日志如下：

```
...
Sep 12 13:52:00 ubuntu systemd[1]: Dependency failed for Docker Application Container Engine.
Sep 12 13:52:00 ubuntu systemd[1]: docker.service: Job docker.service/start failed with result 'dependency'.
```

`systemctl status docker.socket`日志如下：

```
Sep 12 13:52:00 ubuntu systemd[1]: Starting Docker Socket for the API.
Sep 12 13:52:00 ubuntu systemd[1]: docker.socket: Control process exited, code=exited status=216
Sep 12 13:52:00 ubuntu systemd[1]: Failed to listen on Docker Socket for the API.
Sep 12 13:52:00 ubuntu systemd[1]: docker.socket: Unit entered failed state.
```

原因是`docker.socket`中`[Socket] SocketGroup=docker`指定了用户组，我没有设置 docker 用户组，docker 无法监听 socket

所以解决方式： `groupadd docker`

或者：将`docker.socket`中的`SocketGroup=docker`改成`SocketGroup=root`或其他存在的组


再次`systemctl start docker`，成功


## 启动 docker daemon 时出错

系统：`ubuntu 1604`

错误信息：

```
Failed to connect to containerd: failed to dial "/var/run/docker/containerd/docker-containerd.sock": dial unix:///var/run/docker/containerd/docker-containerd.sock: timeout
```

原因：

我是在 k8s 的一个 node 上操作的。强制删除容器，使用 nfs 网络存储的容器没有卸载（通过`mount`可以看到）

解决方法：

通过 `mount|awk '/:/ { print $3 }'|xargs sudo umount -f`强制卸载所有 nfs 的挂载

重新`systemctl start docker`

参考： https://github.com/docker/for-linux/issues/274



## `docker push sth`到私有仓库时，出现“error parsing HTTP 400 response body: invalid character 'F' looking for beginning of value: "Failed parsing or buffering the chunk-encoded client body.\r\n"”

这是因为 docker daemon 使用了代理，在`vim /lib/systemd/system/docker.service.d/http-proxy.conf`中将私有仓库地址加到`no_proxy`中

```
[Service]
Environment="HTTP_PROXY=0.0.0.0:5679" "HTTPS_PROXY=0.0.0.0:5679" "NO_PROXY=localhost,127.0.0.1,[私有仓库地址]"
```
## 在 dockerfile 里 `yum install xx`出现`Rpmdb checksum is invalid: dCDPT(pkg checksums) `

`RUN yum -y install openssh-server passwd supervisor ; yum clean all`

https://github.com/CentOS/sig-cloud-instance-images/issues/15


## containerd 添加 insecure registry

查看配置文件

`systemctl status containerd` 


`cat /etc/systemd/system/containerd.service.d/20-change-config.conf`

看到

`Environment=CONTAINERD_CONFIG=/etc/containerd/config.toml`

`vi /etc/containerd/config.toml`

在 `[plugins] [plugins.cri] [plugins.cri.registry.auths]` 下添加：

```
      [plugins.cri.registry.mirrors."registry.local"]
        endpoint = ["http://10.10.10.47:80"]
```

重启 containerd

`systemctl restart containerd`
# 让docker使用代理

## 创建目录

CentOS

`mkdir -p /etc/systemd/system/docker.service.d`

Ubuntu

`mkdir -p /lib/systemd/system/docker.service.d`

## 创建配置文件

CentOS

`vim /etc/systemd/system/docker.service.d/http-proxy.conf`

Ubuntu

`vim /lib/systemd/system/docker.service.d/http-proxy.conf`

## 写入以下数据

```
[Service]
Environment="HTTP_PROXY=ip:port/"
Environment="HTTPS_PROXY=ip:port/"
```

## 更新配置

`sudo systemctl daemon-reload`

## 检查配置

`systemctl show  docker|grep Environment`

## 正常会包含以下信息

`Environment=HTTP_PROXY=ip:port/ HTTPS_PROXY=ip:port/`

## 重启docker

`sudo systemctl restart docker`

