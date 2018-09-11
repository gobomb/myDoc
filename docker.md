# docker 设置

## docker deamn 重启但容器不重启

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

