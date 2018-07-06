# virtralbox 配置网卡

## Ubuntu 虚拟机

参考：https://www.jianshu.com/p/cc6ed627b5d4

1. 为宿主机添加 Host-Only 网络，在宿主机中查看网段(192.168.57.0/24)

2. 为虚拟机添加 Host-Only 网卡

3. 启动虚拟机，设置静态 IP

此时 ifconfig 只有一块网卡（nat）

`vim /etc/network/interfaces`

```
auto eth0
iface eth0 inet dhcp

auto eth1
iface eth1 inet static
address 192.168.57.2 #需和同一网段宿主机网段
netmask 255.255.255.0
``` 

5. 重启网卡

```
#ifdown eth0 && ifup eth0

ifdown eth1 && ifup eth1
```


6. ifconfig 查看已有两张网卡

此时可以与宿主机互ping通

## CentOS

1、2步和Ubuntu相同

3. ifconfig 查看到有两张网卡，记住新网卡相关信息

4. 配置新网卡信息

```
cd /etc/sysconfig/network-scripts

vim ifcfg-enp0s8
```


```
TYPE=Ethernet
HWADDR=08:00:47:5b:d5:8a #网卡mac地址
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=static		 #静态地址
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=stable-privacy
NAME=enp0s8 			#网卡名字
UUID=018c95cb-6b35-32f9-8b9c-490067c17d99 #需与其他网卡不同
DEVICE=enp0s8
ONBOOT=yes

IPADDR=192.168.56.8     #静态ip
NETMASK=255.255.255.0   #掩码
GATEWAY=192.168.56.1    #默认网关

```

5. 重启网络

```
service network restart
```


## 添加静态路由方法

```
ip route add 172.16.100.0/24 via 192.168.6.249

ip route del 172.16.100.0/24 via 192.168.6.249
```

## eth0 手动向 dhcp 获取 IP

```
dhclient eth0
```

当 Host-only 网卡配置成功，会出现宿主机虚拟机相互 ping 得通但宿主机无法 ssh 成功虚拟机的情况，解决方法是 `dhclient [nat网卡]`，原因暂时不明。

