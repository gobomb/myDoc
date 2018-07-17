

# 在 docker 中搭建 elasticsearch 集群

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
