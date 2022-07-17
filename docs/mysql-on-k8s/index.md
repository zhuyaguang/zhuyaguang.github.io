# Mysql on K8s


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

### RadonDB


