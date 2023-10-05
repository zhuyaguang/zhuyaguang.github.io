# ElasticSearch 权威指南笔记


<!--more-->

## 入门

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

查看集群健康状态

```shell
GET	/_cluster/health
```



## 索引

#### 索引一个文档

使用自己的**ID**

```shell
PUT	/{index}/{type}/{id}
{
"field":	"value",
		...
}
```

自增**ID**

```shell
POST	/website/blog/
{
"title":	"My	second	blog	entry",
"text":		"Still	trying	this	out...",
"date":		"2014/01/01"
}
```

#### 检索文档

```
GET	/website/blog/123?pretty
```

> **pretty**	
>
> 在任意的查询字符串中增加	pretty	参数，类似于上面的例子。会让Elasticsearch美化输出**(pretty-print)** JSON 响应以
>
> 便更加容易阅读。	_source	字段不会被美化，它的样子与我们输入的一致。

检索文档的一部分

```
GET	/website/blog/123?_source=title,text
```

你只想得到	_source	字段而不要其他的元数据

```
GET	/website/blog/123/_source
```

#### 更新整个文档

```shell
PUT	/website/blog/123
{
"title":	"My	first	blog	entry",
"text":		"I	am	starting	to	get	the	hang	of	this...",
"date":		"2014/01/02"
}
```

#### 创建一个新文档

```
POST	/website/blog/
{	...	}
```

不重复插入

```
PUT	/website/blog/123?op_type=create
{	...	}
```

```
PUT	/website/blog/123/_create
{	...	}
```

#### 删除文档

```
DELETE	/website/blog/123
```


