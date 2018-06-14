# 从历史命令中过滤start的第8行并排除第一列然后追加到start.md

```
history|grep start|head -n 8|tail -n 1|awk '{$1="";print $0}'>>start.md
```


