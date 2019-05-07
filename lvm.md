(Ubuntu 1604)

# 查看现有磁盘及分区

`sudo fdisk -l`

# 查看文件系统挂载目录

`df -h`

# 解除挂载

`sudo umount -l /mnt`

//# 格式化磁盘和分区

//`sudo fdisk /dev/sdb`

//具体过程依照交互命令


# 创建物理卷

`sudo pvcreate /dev/sdb1`

# 创建卷组

`sudo vgcreate vg0 /dev/sdb1`

## 物理卷加入已有卷组

`sudo vgextend vg0 /dev/sdc`

# 创建逻辑卷

`sudo lvcreate -L 60g vg0 -n elastic`



# 激活逻辑卷

	
```
modprobe dm-mod
sudo vgscan
sudo vgchange -ay
```

# 格式化逻辑卷

`sudo mkfs.ext4  /dev/mapper/vg0-elastic`

# 挂载

```
sudo mkdir /mnt/elastic

sudo mount /dev/mapper/vg0-elastic /mnt/elastic

```

# 查看物理卷、卷组、逻辑卷

```
pvs
pvdisplay
vgs
vgdisplay
lvs
lvdisplay
```

# 逻辑卷在线扩容

扩增到200G：

```
sudo lvextend -L 200G /dev/vg0/esrally 

sudo resize2fs /dev/vg0/esrally

# or ` xfs_growfs /dev/centos/root`
```

# 参考

https://wiki.archlinux.org/index.php/LVM


# 新增 swap 分区

`sudo lvcreate -L 4g vg0 -n swap`

`sudo mkswap /dev/vg0/swap`

`vi /etc/fstab`:

`/dev/mapper/vg0-swap   swap            swap            defaults        0 0`


```
$ sudo swapon -va
swapon: /dev/mapper/root-swap: found signature [pagesize=4096, signature=swap]
swapon: /dev/mapper/root-swap: pagesize=4096, swapsize=4294967296, devsize=4294967296
swapon /dev/mapper/root-swap
```

`free -h`

```
...
Swap:         4.0Gi          0B       4.0Gi
```

参考：

https://linux.cn/article-9579-1.html

# 删除 lv

1. umount

`umount /dev/ctg-data/log`

2. 移除逻辑卷

`lvremove /dev/ctg-data/log`

3. `lvdisply`

可以看到该逻辑卷已经移除


