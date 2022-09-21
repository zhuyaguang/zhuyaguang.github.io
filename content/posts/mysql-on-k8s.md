---
title: "K8s 上的中间件"
date: 2022-07-16T13:53:33+08:00
draft: false
description: "mysql上k8s方案汇总"
featuredImage: https://bartlomiejmika.com/img/2022/07/ian-taylor-jOqJbvo1P9g-unsplash.jpg
---

<!--more-->

# K8S 上部署 mysql、redis、minio方案



## docker 部署

Minio简单版：

~~~
docker run \
  -p 9000:9000 \
  -p 9001:9001 \
  --name zj-minio \
  -v ~/minio/data:/data \
  -e "MINIO_ROOT_USER=admin" \
  -e "MINIO_ROOT_PASSWORD=root123456" \
  quay.io/minio/minio server /data --console-address ":9001"
  
  mkdir -p ~/minio/data

数据迁移至：~/minio/data

~~~

Redis 简单版

~~~
docker run -itd --name zj-redis -p 6379:6379 redis
~~~

Mysql 简单版

~~~
sudo docker run -p 3306:3306 --name zjmysql \
-v /usr/local/docker/mysql/conf:/etc/mysql \
-v /usr/local/docker/mysql/logs:/var/log/mysql \
-v /usr/local/docker/mysql/data:/var/lib/mysql \
-e MYSQL_ROOT_PASSWORD=123456 \
-d mysql:5.7

数据迁移至:/usr/local/docker/mysql/data
~~~

备份：无

高可用：无

## 手动 yaml 部署

### mysql

1.为机器打label

```
kubectl label node node1xx mysql=true --overwrite
```

2.创建pv，pvc，根据自己的实际情况创建(内置的账号密码为root/admin)

```
kubectl apply -f pv-pvc-hostpath.yaml   

kubectl apply -f service.yaml     

kubectl apply -f configmap-mysql.yaml   

kubectl apply -f deploy.yaml  
```

3.校验mysql的pv和pvc是否匹配完成

4.本地调试可以使用docker启动mysql

~~~
docker run -p 3306:3306 --name mysql -e MYSQL_ROOT_PASSWORD=admin -d mysql:5.7  
~~~

## operator 部署

### RadonDB for mysql

```
helm repo add radondb https://radondb.github.io/radondb-mysql-kubernetes/

helm install demo radondb/mysql-operator

kubectl apply -f https://github.com/radondb/radondb-mysql-kubernetes/releases/latest/download/mysql_v1alpha1_mysqlcluster.yaml


```



添加用户

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: sample-user-password   # 密钥名称。应用于 MysqlUser 中的 secretSelector.secretName。  
data:
  pwdForSample: UmFkb25EQkAxMjMKIA==  #密钥键，应用于 MysqlUser 中的 secretSelector.secretKey。示例密码为 base64 加密的 RadonDB@123
  # pwdForSample2:
  # pwdForSample3:
```



```yaml
apiVersion: mysql.radondb.com/v1alpha1
kind: MysqlUser
metadata:
 
  name: sample-user-cr  # 用户 CR 名称，建议使用一个用户 CR 管理一个用户。
spec:
  user: sample_user  # 需要创建/更新的用户的名称。
  hosts:            # 支持访问的主机，可以填多个，% 代表所有主机。 
       - "%"
  permissions:
    - database: "*"  # 数据库名称，* 代表所有数据库。 
      tables:        # 表名称，* 代表所有表。
         - "*"
      privileges:     # 权限，参考 https://dev.mysql.com/doc/refman/5.7/en/grant.html。
         - SELECT
  
  userOwner:  # 指定被操作用户所在的集群。不支持修改。  
    clusterName: sample
    nameSpace: default # radondb mysql 集群所在的命名空间。
  
  secretSelector:  # 指定用户的密钥和保存当前用户密码的键。
    secretName: sample-user-password  # 密钥名称。   
    secretKey: pwdForSample  # 密钥键，一个密钥可以保存多个用户的密码，以键区分。
```



### 备份、恢复



