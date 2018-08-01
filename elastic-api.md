## 版本 5.6.10

## 基本概念

```
cluster
node
index
type
document
shards
replicas(replica for shards)
```

默认情况下, 每个index会被分配5个shards和1个replica

## restful API:

the pattern of access date in elastic
`<REST Verb> /<Index>/<Type>/<ID>`


```
curl -X GET "localhost:9200/_cat/health?v"
curl -X GET "localhost:9200/_cat/nodes?v"
curl -X GET "localhost:9200/_cat/indices?v"
curl -X PUT "localhost:9200/customer?pretty"

# 插入文档
curl -X PUT "localhost:9200/customer/external/1?pretty" -H 'Content-Type: application/json' -d'
{
  "name": "John Doe"
}
'

curl -X GET "localhost:9200/customer/external/1?pretty"

# 删除 index
curl -X DELETE "localhost:9200/customer?pretty"
curl -X GET "localhost:9200/_cat/indices?v"

# 指定 id replace（若该 id 的文档存在，否则 create）
curl -X PUT "localhost:9200/customer/external/1?pretty" -H 'Content-Type: application/json' -d'
{
  "name": "Jane Doe"
}
'

# 不指定 id，则自动生成 id
curl -X POST "localhost:9200/customer/external?pretty" -H 'Content-Type: application/json' -d'
{
  "name": "Jane Doe"
}
'

# update（deletes the old document and then indexes a new document）
curl -X POST "localhost:9200/customer/external/1/_update?pretty" -H 'Content-Type: application/json' -d'
{
  "doc": { "name": "Jane Doe" }
}
'

# 添加字段
curl -X POST "localhost:9200/customer/external/1/_update?pretty" -H 'Content-Type: application/json' -d'
{
  "doc": { "name": "Jane Doe", "age": 20 }
}
'

# 使用简单的脚本进行 update
curl -X POST "localhost:9200/customer/external/1/_update?pretty" -H 'Content-Type: application/json' -d'
{
  "script" : "ctx._source.age += 5"
}
'

curl -X POST "localhost:9200/customer/external/_bulk?pretty" -H 'Content-Type: application/json' -d'
{"update":{"_id":"1"}}
{"doc": { "name": "John Doe becomes Jane Doe" } }
{"delete":{"_id":"2"}}
'

# 查询

# URI 形式
curl -X GET "localhost:9200/bank/_search?q=*&sort=account_number:asc&pretty"

# JSON 形式
curl -X GET "localhost:9200/bank/_search?pretty" -H 'Content-Type: application/json' -d'
{
  "query": { "match_all": {} },
  "sort": [
    { "account_number": "asc" }
  ]
}
'

# size defaults to 10
curl -X GET "localhost:9200/fd87783e78e104a10a0b1d1f6c0fc85c1-std/_search?pretty" -H 'Content-Type: application/json' -d'
{
  "query": { "match_all": {} },
  "size": 3
}
'

# 定义 _source 的字段
curl -X GET "localhost:9200/bank/_search?pretty" -H 'Content-Type: application/json' -d'
{
  "query": { "match_all": {} },
  "_source": ["account_number", "balance"]
}
'

#  包含 mill 或 lane
curl -X GET "localhost:9200/bank/_search" -H 'Content-Type: application/json' -d'
{
  "query": { "match": { "address": "mill lane" } }
}
'
# 包含 mill lane
curl -X GET "localhost:9200/bank/_search" -H 'Content-Type: application/json' -d'
{
  "query": { "match_phrase": { "address": "mill lane" } }
}
'

# 使用 bool 逻辑进行查询 must，should，must not
curl -X GET "localhost:9200/bank/_search?pretty" -H 'Content-Type: application/json' -d'
{
  "query": {
    "bool": {
      "must": [
        { "match": { "address": "mill" } },
        { "match": { "address": "lane" } }
      ]
    }
  }
}
'

curl -X GET "localhost:9200/bank/_search" -H 'Content-Type: application/json' -d'
{
  "query": {
    "bool": {
      "must": [
        { "match": { "age": "40" } }
      ],
      "must_not": [
        { "match": { "state": "ID" } }
      ]
    }
  }
}
'

# 聚合搜索
curl -X GET "localhost:9200/bank/_search?pretty" -H 'Content-Type: application/json' -d'
{
  "size": 0,
  "aggs": {
    "group_by_state": {
      "terms": {
        "field": "state.keyword"
      }
    }
  }
}
'


```


`took` 花费的毫秒数

`_score` 查询的相关度


## docker 启动 elasitc 的注意事项

https://www.elastic.co/guide/en/elasticsearch/reference/5.6/docker.html#_notes_for_production_use_and_defaults