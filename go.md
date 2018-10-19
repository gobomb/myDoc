# 在 Ubuntu 下编译到到 Alpine 需要用到：

`CGO_ENABLED=0 GOOS=linux go build -a  -o go-gin-example .`

`CGO_ENABLED=0`关闭 cgo，在构建过程中会忽略 cgo 并静态链接所有的依赖库，而开启 cgo 后，方式将转为动态链接（默认是开启的）

`-a` 强制重新编译，不利用缓存或已编译好的部分文件，直接所有包都是最新的代码重新编译和关联

不然会报错：

`panic: standard_init_linux.go:175: exec user process caused "no such file or directory"`

如果要使用cgo可以通过go build --ldflags "-extldflags -static" 来让gcc使用静态编译。

参考：https://yryz.net/post/golang-docker-alpine-start-panic.html
