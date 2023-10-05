---
title: "ElasticSearch"
date: 2023-10-05T08:44:30+08:00
draft: true
description: "ES 权威指南读书笔记"
---

<!--more-->

### 简单搜索

检查 ES 集群状态

```shell
curl	'http://localhost:9200/?pretty'
```

关系型数据库和ES字段的对应关系

```shell
Relational	DB	->	Databases	->	Tables	->	Rows	->	Columns
Elasticsearch	->	Indices			->	Types		->	Documents	->	Fields
```

插入一条数据

```shell
PUT	/megacorp/employee/1 {
"first_name"	:	"John",
"last_name"	:		"Smith",
"age"	:								25,
"about"	:						"I	love	to	go	rock	climbing",
"interests":	[	"sports",	"music"	]
}
```

查询文档

```shell
GET	/megacorp/employee/1
```

搜索全部员工

```shell
GET	/megacorp/employee/_search
```

搜索姓氏中包含**“Smith”**的员工

```shell
GET	/megacorp/employee/_search?q=last_name:Smith
```

使用  **DSL(Domain Specific Language**)特定领域语言**)**查询

```shell
GET	/megacorp/employee/_search
{
  "query": {
    "match": {
      "last_name": "Smith"
    }
  }
}
```

找到姓氏为“Smith”的员工，但是我们只想得到年龄大于30岁的

```shell
GET	/megacorp/employee/_search
{
  "query": {
    "filtered": {
      "filter": {
        "range": {
          "age": {
            "gt": 30
          }
        }
      },
      "query": {
        "match": {
          "last_name": "smith"
        }
      }
    }
  }
}
```

### 全文搜索

搜索所有喜欢**“rock climbing”**的员工

```shell
GET	/megacorp/employee/_search
{
"query"	:	{
"match"	:	{
"about"	:	"rock	climbing"
								}
				}
}
```

#### 短语搜索

要查询同时包含"rock"和"climbing"（并且是相邻的）的员工记录

```shell
GET	/megacorp/employee/_search
{
"query"	:	{
"match_phrase"	:	{
"about"	:	"rock	climbing"
								}
				}
}
```

高亮我们的搜索

```shell
GET	/megacorp/employee/_search
{
  "query": {
    "match_phrase": {
      "about": "rock climbing"
    }
  },
  "highlight": {
    "fields": {
      "about": {}
    }
  }
}				
```

### 分析

到所有职员中最大的共同点（兴趣爱好）是什么

```shell
GET	/megacorp/employee/_search
{
"aggs":	{
"all_interests":	{
"terms":	{	"field":	"interests"	}
				}
		}
}
```

所有姓"Smith"的人最大的共同点（兴趣爱好）

 ```shell
 GET	/megacorp/employee/_search
 {
   "query": {
     "match": {
       "last_name": "smith"
     }
   },
   "aggs": {
     "all_interests": {
       "terms": {
         "field": "interests"
       }
     }
   }
 }
 ```

统计每种兴趣下职员的平均年龄

```shell
GET	/megacorp/employee/_search
{
  "aggs": {
    "all_interests": {
      "terms": {
        "field": "interests"
      },
      "aggs": {
        "avg_age": {
          "avg": {
            "field": "age"
          }
        }
      }
    }
  }
}
```

