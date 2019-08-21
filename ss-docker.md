# 通过 docker 一键启动代理及将 socks5 转换成 http 代理方案

## 方案一 带kcp优化版本

依赖：docker

### 服务端

`docker run  -dt  --name ssserver -p $tcp_port:6443 -p $udp_port:6500/udp mritd/shadowsocks -m "ss-server" -s "-s 0.0.0.0 -p 6443 -m aes-256-cfb -k $pwd --fast-open" -x -e "kcpserver" -k "-t 127.0.0.1:6443 -l :6500 -mode fast2"`

以下参数根据需要修改：

`-p $tcp_port:6443` - $tcp_port替换为tcp端口

`-p $udp_port:6500` - $udp_port替换为udp端口

`-k $pwd` - $pwd替换为密码

### 客户端

`docker run  -dt  --name ssclient -p $tcp_port:1080 mritd/shadowsocks -m "ss-local" -s "-s 127.0.0.1 -p 6500 -b 0.0.0.0 -l 1080 -m aes-256-cfb -k [password] --fast-open" -x -e "kcpclient" -k "-r $server_ip:$udp_port -l :6500 -mode fast2"`

`-p $tcp_port:1080` - $tcp_port替换为本地tcp端口，默认为socks；欲使用http代理需使用`privoxy`进行转换，见方案三

`-r $server_ip:$udp_port` - $server_ip/$udp_port分别替换为服务端ip和服务端udp端口（上述udp端口）

`-k $pwd` - $pwd替换为密码（为上述服务器密码）

安全起见，所有 shell 变量（$xxx)根据自己实际情况自行替换，其他参数没有需要无需修改

## 方案二 客户端使用 polipo 将 socks 代理转换成http代理

依赖：docker、docker-compose

`vim docker-compose.yml`

```
version: '2'

services:
  ss:
    container_name: ss
    image: vimagick/shadowsocks-libev
    command: ss-local -s  ss_server_ip -p ss_server_port -b 0.0.0.0 -l 1080 -k ss_server_pwd -m aes-256-cfb
    ports:
      - "1080:1080"
    restart: always

  polipo:
    container_name: polipo
    image: vimagick/polipo
    command:
    #  authCredentials=user:passwd
      socksParentProxy=ss:1080 # 本地socks端口
    ports:
      - "8123:8123" # 转换的http代理端口
    restart: always
```

启动（在 docker-compose.yml 所在目录）：

`docker-compose up -d`

关闭：

`docker-compose down`


## 方案三 （推荐）

依赖：docker

### 原生ss服务端：

`export server_port=ss服务器端口`

`export server_pwd=ss服务端密码`

`export server_protocol=ss服务端加密协议`

`docker run -d -p $server_port:1984 oddrationale/docker-shadowsocks -s 0.0.0.0 -p 1984 -k $server_pwd -m $server_protocol`

//aes-256-cfb

### 客户端连接原生 ss 并通过 privoxy 一键提供 http 代理

`export server_ip=ss服务端ip`

`export server_port=ss服务器端口`

`export server_pwd=ss服务端密码`

`export server_protocol=ss服务端加密协议`


`docker run --name=sslocal -d  vimagick/shadowsocks-libev ss-local -s  $server_ip -p $server_port -b 0.0.0.0 -l 1080 -k $server_pwd -m $server_protocol && docker run -p 5679:5679 -d -e PROXY_PORT=5679 -e SOCKS_IP_PORT=$(docker inspect --format='{{.NetworkSettings.IPAddress}}' sslocal):1080 --name=privoxy gobomb/privoxy4socks`

`export http_proxy=0.0.0.0:5679 && export https_proxy=0.0.0.0:5679`

