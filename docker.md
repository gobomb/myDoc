# docker 设置

## docker daemon 重启但容器不重启

1. `vim /etc/docker/daemon.json`

    ```
    {
    ...
          "live-restore": true,
    ...
    ```
    
2. `vim /usr/lib/systemd/system/docker.service`
  
    ```
    ...
    # kill only the docker process, not all processes in the cgroup
    KillMode=process
    ...
    ```
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
