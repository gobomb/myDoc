# 使用docker+frp访问nat背后的sshd

访问其他tcp端口同理

## server 端


vim ~/conf/frps.ini

```
  [common]
  bind_port = 7000

```

docker run -v ~//conf:/conf -p 7000:7000 -p 7022:7022 -d --name frps gobomb/frp:20190702 -c /conf/frps.ini

这里的7000为server端监听端口，即client端配置中的server_port

这里的7022为client端的remote_ip

## client 端

vim ~/conf/frpc.ini

```
  [common]
  server_addr = [server_ip]
  server_port = 7000
 
  [local_ssh]
  type = tcp
  local_ip = [the_ip_of_the_machine_before_nat] # not the localhost because the localhost is the ip of the container which the frpc run in
  local_port = 22
  remote_port = 7022
```

server_ip为server的公网ip

server_port、remote_port与server暴露的端口保持一致（7000、7022）

docker run -v ~/git/frp/conf:/conf -d --restart=always --entrypoint /frpc gobomb/frp:20190702 -c /conf/frpc.ini

## 访问方式

ssh [usr]@[servr_ip] -p 7022

## reverse the socks5 proxy

on the client:

ssh -NfD 2222 [user]@[ip_before_nat]

vim conf/frpc.ini

```
...
[local_socks]
type = tcp
local_ip = [ip_before_nat]
local_port = 2222
remote_port = 7222
```

on the server:

map the 7222 tcp port when start the fprs container
