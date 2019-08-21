# 设置内存

虚拟内存分配太少启动会报错：

```
Jul 20 14:53:46 scratchpad elasticsearch: [1]: max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]
```

解决：

```
$ vim /etc/sysctl.conf 

vm.max_map_count=262144

$ sysctl -w vm.max_map_count=262144
```

# 在 docker 中搭建 elasticsearch 集群（单机）

1. 创建docker自定义网络：

	`docker network  create --subnet=172.18.0.0/16 elasnet`

2. 创建宿主机目录

	es-node0 节点：

	```
	# 创建并进入配置目录
	mkdir -p /root/temp/es-node0 && cd $_

	# elasticsearch.yml 配置文件
	echo 'cluster.name: "cluster"
	node.name: node-0
	node.master: true
	node.data: true
	network.host: 0.0.0.0
	discovery.zen.ping.unicast.hosts: ["172.18.0.200", "172.18.0.201"]
	discovery.zen.minimum_master_nodes: 1
	discovery.zen.ping_timeout: 3s' > elasticsearch.yml

    # log4j2.properties 文件
	echo 'status = error

	appender.console.type = Console
	appender.console.name = console
	appender.console.layout.type = PatternLayout
	appender.console.layout.pattern = [%d{ISO8601}][%-5p][%-25c{1.}] %marker%m%n

	rootLogger.level = info
	rootLogger.appenderRef.console.ref = console' > log4j2.properties

	# scripts 目录
	mkdir scripts

	```

	es-node1 节点：

	```
	mkdir -p /root/temp/es-node1 && cd $_

	echo 'cluster.name: "cluster"
	node.name: node-1
	node.master: true
	node.data: true
	network.host: 0.0.0.0
	discovery.zen.ping.unicast.hosts: ["172.18.0.200", "172.18.0.201"]
	discovery.zen.minimum_master_nodes: 1
	discovery.zen.ping_timeout: 3s' > elasticsearch.yml

	echo 'status = error

	appender.console.type = Console
	appender.console.name = console
	appender.console.layout.type = PatternLayout
	appender.console.layout.pattern = [%d{ISO8601}][%-5p][%-25c{1.}] %marker%m%n

	rootLogger.level = info
	rootLogger.appenderRef.console.ref = console' > log4j2.properties

	mkdir scripts

	```


3. docker run elasticsearch


	`docker run -d --name es-node0 -p 9200:9200 -v /root/temp/es-node0:/usr/share/elasticsearch/config -e ES_JAVA_OPTS="-Xms512m -Xmx512m" -e xpack.security.enabled=false --net elasnet --ip 172.18.0.200 elasticsearch`


	`docker run -d --name es-node1 --link es-node0 -v /root/temp/es-node1:/usr/share/elasticsearch/config -e ES_JAVA_OPTS="-Xms512m -Xmx512m" -e xpack.security.enabled=false --net elasnet --ip 172.18.0.201 elasticsearch`

4. 验证是否成功

	`curl 0.0.0.0:9200/_cat/health\?v` 得到结果：

	```
	epoch      timestamp cluster status node.total node.data shards pri relo init unassign pending_tasks max_task_wait_time active_shards_percent
	1531811619 07:13:39  cluster green           2         2      0   0    0    0        0             0                  -                100.0%
	```


	`curl 0.0.0.0:9200/_cat/nodes\?v` 得到结果：

	```
	ip           heap.percent ram.percent cpu load_1m load_5m load_15m node.role master name
	172.18.0.200           15          96  35    0.44    0.12     0.08 mdi       -      node-0
	172.18.0.201           10          96   1    0.44    0.12     0.08 mdi       *      node-1
	```

	可以看到有两个节点，集群状态为 green，说明配置成功。


参考： 
1. https://zhuanlan.zhihu.com/p/20690152
2. https://blog.csdn.net/gobitan/article/details/51104362
3. https://www.cnblogs.com/xiaochina/p/6855591.html


## elasticsearch 优化思路
官方建议，设置为系统内存的一半，但不要超过32gb。

https://www.elastic.co/guide/cn/elasticsearch/guide/current/heap-sizing.html

文件描述符

https://www.elastic.co/guide/cn/elasticsearch/guide/current/_file_descriptors_and_mmap.html


# 使用esrally做压力测试

## 在服务端运行：

`docker run -d --name es -p 9200:9200  -e ES_JAVA_OPTS="-Xms1g -Xmx1g" -e xpack.security.enabled=false elasticsearch`


## 在客户端运行：

`docker run -it -v /Users/cym/git/temp/esrally/geonames:/root/track/geonames -v Users/cym/git/temp/esrally/rally-log:/root/.rally/logs rockybean/esrally     esrally race --track-path=/root/track/geonames  --pipeline=benchmark-only  --target-hosts=[ip]:9200 --challenge=insert --offline --report-file=/root/.rally/logs/report`

* /root/track/geonames 是测试数据（已经下载好）
* --challenge 指定预测流程（通过组合 operations 定义一系列 task ，再组合成一个压测的流程）
* --offline 防止 esrally 去下载测试数据 
* –pipeline=benchmark-only 表示测试已有集群
* 


从这里 https://github.com/elastic/rally-tracks 取得 tracks 相关定义，也测试数据放在同一目录下

### challenges/default.json 格式：
```
	{
      "name": "insert",
      "description": "sthing ",
      "index-settings": {
        "index.number_of_replicas": 0
      },
      "schedule": [
        {
          "operation": "index-append",
          "warmup-time-period": 120,
          "clients": 8
        }
      ]
    }
```

### operations/default.json 格式
```
	{
      "name": "index-append",
      "#COMMENT": "This operation-type is called 'bulk' with Rally 0.8.0. This one is only here for backwards-compatibility. Please use 'bulk' in your tracks.",
      "operation-type": "index",
      "bulk-size": {{bulk_size | default(5000)}}
    },
    {
      "name": "index-update",
      "#COMMENT": "This operation-type is called 'bulk' with Rally 0.8.0. This one is only here for backwards-compatibility. Please use 'bulk' in your tracks.",
      "operation-type": "index",
      "bulk-size": {{bulk_size | default(5000)}},
      "conflicts": "random"
    },
    {
      "name": "force-merge",
      "operation-type": "force-merge"
    },
    {
      "name": "refresh",
      "operation-type": "refresh"
    }
```

### track.json 需和测试数据放在同一个目录下面

```
{% import "rally.helpers" as rally with context %}

{
  "version": 1,
  "short-description": "POIs from Geonames",
  "description": "POIs from Geonames",
  "data-url": "http://benchmarks.elasticsearch.org.s3.amazonaws.com/corpora/geonames",
  "indices": [
    {
      "name": "geonames",
      "types": [
        {
          "name": "type",
          "mapping": "mappings.json",
          "documents": "documents-2.json.bz2",
          "document-count": 11396505,
          "compressed-bytes": 264698741,
          "uncompressed-bytes": 3547614383
        }
      ]
    }
  ],
  "operations": [
    {{ rally.collect(parts="operations/*.json") }}
  ],
  "challenges": [
    {{ rally.collect(parts="challenges/*.json") }}
  ]
}
```

## 常用命令：

查询indices： `curl [ip]:9200/_cat/indices\?v`

查询健康状态： `curl [ip]:9200/_cat/health\?v`

查询某个index数据： `curl [ip]:9200/geonames/_search\?pretty`

查看节点： `curl [ip]:9200/_cat/nodes\?v`

本地压测： `esrally race --track=logging --challenge=append-no-conflicts --car="4gheap"`

## 压测结果

服务器是1.5g内存



```
|   Lap |                         Metric |                      Task |   Value |   Unit |
|------:|-------------------------------:|--------------------------:|--------:|-------:|
|   All |                  Indexing time |                           |       0 |    min |
|   All |                     Merge time |                           |       0 |    min |
|   All |                   Refresh time |                           |       0 |    min |
|   All |                     Flush time |                           |       0 |    min |
|   All |            Merge throttle time |                           |       0 |    min |
|   All |             Total Young Gen GC |                           |       0 |      s |
|   All |               Total Old Gen GC |                           |       0 |      s |
|   All |                 Min Throughput |              index-append |  360.51 | docs/s |
|   All |              Median Throughput |              index-append |  423.79 | docs/s |
|   All |                 Max Throughput |              index-append |  656.03 | docs/s |
|   All |        50th percentile latency |              index-append | 93.9785 |     ms |
|   All |        90th percentile latency |              index-append | 189.019 |     ms |
|   All |        99th percentile latency |              index-append | 62623.8 |     ms |
|   All |      99.9th percentile latency |              index-append | 75323.3 |     ms |
|   All |       100th percentile latency |              index-append | 83774.3 |     ms |
|   All |   50th percentile service time |              index-append | 93.9785 |     ms |
|   All |   90th percentile service time |              index-append | 189.019 |     ms |
|   All |   99th percentile service time |              index-append | 62623.8 |     ms |
|   All | 99.9th percentile service time |              index-append | 75323.3 |     ms |
|   All |  100th percentile service time |              index-append | 83774.3 |     ms |
|   All |                     error rate |              index-append |   97.48 |      % |
|   All |       100th percentile latency |       refresh-after-index | 52.2179 |     ms |
|   All |  100th percentile service time |       refresh-after-index | 52.2179 |     ms |
|   All |                     error rate |       refresh-after-index |     100 |      % |
|   All |       100th percentile latency |               force-merge | 50.6665 |     ms |
|   All |  100th percentile service time |               force-merge | 50.6665 |     ms |
|   All |                     error rate |               force-merge |     100 |      % |
|   All |       100th percentile latency | refresh-after-force-merge | 54.9204 |     ms |
|   All |  100th percentile service time | refresh-after-force-merge | 54.9204 |     ms |
|   All |                     error rate | refresh-after-force-merge |     100 |      % |
|   All |        50th percentile latency |               index-stats | 50330.7 |     ms |
|   All |        90th percentile latency |               index-stats | 68900.9 |     ms |
|   All |        99th percentile latency |               index-stats | 73024.3 |     ms |
|   All |      99.9th percentile latency |               index-stats | 73413.7 |     ms |
...
```

## 官方提供的测试数据

Geonames(geonames): for evaluating the performance of structured data.
Geopoint(geopoint): for evaluating the performance of geo queries.
Percolator(percolator): for evaluating the performance of percolation queries.
PMC(pmc): for evaluating the performance of full text search.
NYC taxis(nyc_taxis): for evaluating the performance for highly structured data.
Nested(nested): for evaluating the performance for nested documents.
Logging(logging): for evaluating the performance of (Web) server logs.
noaa(noaa): for evaluating the performance of range fields.



## 参考：

https://segmentfault.com/a/1190000011174694?_ea=2549617

https://segmentfault.com/a/1190000011966008

http://esrally.readthedocs.io/en/latest/index.html

https://elasticsearch-benchmarks.elastic.co/#
