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

#### 文档局部更新

添加一个 tags 字段和一个 views 字段：

```shell
POST	/website/blog/1/_update
{
"doc"	:	{
"tags"	:	[	"testing"	],
"views":	0
			}
}
```

#### 检索多个文档

```shell
GET	/_mget
{
  "docs": [
    {
      "_index": "website",
      "_type": "blog",
      "_id": 2
    },
    {
      "_index": "website",
      "_type": "pageviews",
      "_id": 1,
      "_source": "views"
    }
  ]
}
```

如果你想检索的文档在同一个 _index 中（甚至在同一个 _type 中），你就可以在URL中定义一个默认的  _index 或 

者 / _index/_  type 。

```shell
GET	/website/blog/_mget
{
"docs"	:	[
						{	"_id"	:	2	},
						{	"_type"	:	"pageviews",	"_id"	:			1	}
			]
}
```

如果所有文档具有相同	_index	和	_type	

```shell
GET	/website/blog/_mget
{
"ids"	:	[	"2",	"1"	]
}
```

#### 	bulk API

```shell
{	action:	{	metadata	}}\n
{	request	body								}\n
{	action:	{	metadata	}}\n
{	request	body								}\n
...
```

## 搜索

空搜索

```
GET	/_search
```

![image-20231006083735036](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20231006083735036.png)

查询所有类型为 tweet 并在 tweet 字段中包含 elasticsearch 字符的文档

```
GET	/_all/tweet/_search?q=tweet:elasticsearch
```



返回包含	"mary"	字符的所有文档的简单搜索

```
GET	/_search?q=mary
```

用户的名字是“Mary”

“Mary”发的六个推文

针对“@mary”的一个推文

![image-20231006084627477](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20231006084627477.png)

## 映射及分析

查看 mapping

```
GET	/gb/_mapping/tweet
```



![image-20231006090147087](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20231006090147087.png)

![image-20231006090208053](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20231006090208053.png)

## 结构化查询 **Query DSL**

匹配所有的文档

```shell
GET	/_search
{
"query":	{
"match_all":	{}
				}
}
```

使用 match 查询子句用来找寻在 tweet 字段中找寻包含 elasticsearch 的成员

```shell
{
"match":	{
"tweet":	"elasticsearch"
				}
}
```



## 自定义分析器

```shell
PUT	/my_index
{
				"settings":	{
								"analysis":	{
												"char_filter":	{	...	custom	character	filters	...	},
												"tokenizer":			{	...				custom	tokenizers					...	},
												"filter":						{	...			custom	token	filters			...	},
												"analyzer":				{	...				custom	analyzers						...	}
								}
				}
}
```
































