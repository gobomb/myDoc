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

# 参考

https://wiki.archlinux.org/index.php/LVM
