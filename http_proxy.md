# proxy list
# add this to the ~/.bashrc or ~/.zshrc
# the PORT is the the http proxy port provided by ssr or privoxy

PORT=127.0.0.1:1087
export PORT
alias proxy='export http_proxy=$PORT && export https_proxy=$PORT && myip'
alias unproxy='unset http_proxy && unset https_proxy && myip'
alias myip='curl ip.cn'

export no_proxy="localhost,127.0.0.1,localaddress,.localdomain.com"

# if you develop in go you can add this

alias goget='https_proxy=$PORT go get'

# sudo 使用代理

在`/etc/sudoers`中加入：

`Defaults env_keep += "http_proxy https_proxy no_proxy"`

# apt 使用代理

在 `/etc/apt/apt.conf`中加入:

```
Acquire::http::Proxy "http://yourproxyaddress:proxyport";
Acquire::ftp::proxy "ftp://127.0.0.1:8000/";
Acquire::https::proxy "https://127.0.0.1:8000/";
```

上述方法不能用时，可临时指定：

`apt-get -o Acquire::http::proxy="http://127.0.0.1:1087/" update`
