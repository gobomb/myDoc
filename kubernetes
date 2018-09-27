

#  场景：使用官方文档中的yaml创建statefulset的时候出错

https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/

错误：pod has unbound PersistentVolumeClaims

原因：As the cluster used in this tutorial is configured to dynamically provision PersistentVolumes, the PersistentVolumes were created and bound automatically.

解决方法：

去掉yaml中pv的创建部分,k8s会自动分配pv：

```
 volumeMounts:
        - name: www
         mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
  - metadata:
      name: www
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: "my-storage-class"
      resources:
        requests:
          storage: 1Gi
```

#  kubectl delete pod <pod-name> 删除不了

需要启动 pod 所在的 node

# 挂载 nfs 提供的 volume 出错

`kubectl describe po [podname]`可看到如下输出：

```
...
  Warning  FailedMount  2m    kubelet, ubuntu3   MountVolume.SetUp failed for volume "pvc-09cf7a8a-c237-11e8-bbbf-0050568693f8" : mount failed: exit status 32
Mounting command: systemd-run
Mounting arguments: --description=Kubernetes transient mount for /var/lib/kubelet/pods/09db4e8e-c237-11e8-bbbf-0050568693f8/volumes/kubernetes.io~nfs/pvc-09cf7a8a-c237-11e8-bbbf-0050568693f8 --scope -- mount -t nfs 10.10.12.27:/nfs/default-mysql01-pv-claim-pvc-09cf7a8a-c237-11e8-bbbf-0050568693f8 /var/lib/kubelet/pods/09db4e8e-c237-11e8-bbbf-0050568693f8/volumes/kubernetes.io~nfs/pvc-09cf7a8a-c237-11e8-bbbf-0050568693f8
Output: Running scope as unit run-rbc74e570849941fe9a9355219e82ba5d.scope.
mount: wrong fs type, bad option, bad superblock on 10.10.12.27:/nfs/default-mysql01-pv-claim-pvc-09cf7a8a-c237-11e8-bbbf-0050568693f8,
       missing codepage or helper program, or other error
       (for several filesystems (e.g. nfs, cifs) you might
       need a /sbin/mount.<type> helper program)

       In some cases useful info is found in syslog - try
       dmesg | tail or so.
```

到该 pod 所在的 node 机器上（这里是 ubuntu3）上安装 nfs-common：

`apt install nfs-common`
