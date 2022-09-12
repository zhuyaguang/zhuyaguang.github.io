---
title: "多集群实现 PLG 日志收集"
date: 2022-09-07T11:04:28+08:00
draft: false
description: "多集群日志收集系统"
---

<!--more-->

# 多集群实现 PLG 日志收集

## 快速部署 PLG 环境

1. 新建目录保存配置文件

   ```shell
   mkdir -p /data/loki/config && cd /data/loki/config 
   ```

2. 部署 Loki 

   ```shell
   wget https://raw.githubusercontent.com/grafana/loki/v2.6.1/cmd/loki/loki-local-config.yaml -O loki-config.yaml
   docker run --name loki -d -v /data/loki/config:/mnt/config -p 3100:3100 grafana/loki:2.6.1 -config.file=/mnt/config/loki-config.yaml
   ```

3. 部署 promtail

   ````shell
   wget https://raw.githubusercontent.com/grafana/loki/v2.6.1/clients/cmd/promtail/promtail-docker-config.yaml -O promtail-config.yaml
   ````

   ```yaml
   // 修改 promtail 配置文件 
   server:
     http_listen_port: 9080
     grpc_listen_port: 0
   
   positions:
     filename: /tmp/positions.yaml
   
   clients:
     - url: http://10.11.44.49:3100/loki/api/v1/push
   
   scrape_configs:
   - job_name: system
     static_configs:
     - targets:
         - localhost
       labels:
         job: varlogs
         __path__: /var/lib/docker/containers/**/*.log
   ```

   ```shell
   docker run --name promtail -d -v /data/loki/config:/mnt/config -v /var/log:/var/log --link loki grafana/promtail:2.6.1 -config.file=/mnt/config/promtail-config.yaml
   ```

4. 部署 grafana

    ```
    docker run -d --name grafana  -p 3111:3000 grafana/grafana grafana
    ```



### 标签使用方法

单个标签

```yaml
scrape_configs:
 - job_name: system
   pipeline_stages:
   static_configs:
   - targets:
      - localhost
     labels:
      job: syslog
      __path__: /var/log/syslog
```

两个标签

```yaml
scrape_configs:
 - job_name: system
   pipeline_stages:
   static_configs:
   - targets:
      - localhost
     labels:
      job: syslog
      __path__: /var/log/syslog
 - job_name: apache
   pipeline_stages:
   static_configs:
   - targets:
      - localhost
     labels:
      job: apache
      __path__: /var/log/apache.log
```

混合标签

```yaml
scrape_configs:
 - job_name: system
   pipeline_stages:
   static_configs:
   - targets:
      - localhost
     labels:
      job: syslog
      env: dev
      __path__: /var/log/syslog
 - job_name: apache
   pipeline_stages:
   static_configs:
   - targets:
      - localhost
     labels:
      job: apache
      env: dev
      __path__: /var/log/apache.log
```





##   Helm 安装微服务模式的 Loki

Loki 的部署方式有很多种也非常灵活，有微服务部署模式，就是每个组件单独部署，也可以单进程部署。单模块部署相对比较复杂, 每个模块可以单独启动, 不同的模块间通过gRPC服务互相配合提供服务.

![image-20220911064555570](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20220911064555570.png)

1. 下载 chart 包，因为网络原因在线 helm 安装会失败，所以先下载下来。

   ```shell
   helm pull  grafana/loki-distributed
   ```

2. 安装

   ```shell
   helm install loki ./loki-distributed-0.56.7.tgz
   ```

## Helm 安装简单可扩展模式的 Loki

1. 下载 chart 包

   ```
   helm pull grafana/loki-simple-scalable
   ```


## Helm 安装 Loki 全家桶

1. 下载 chart 包

   ```shell
   helm pull grafana/loki-stack
   
   重装之前，先清理下资源
   kubectl delete all --all -n loki
   kubectl delete ns loki
   ```

2. 安装

   ```shell
   kubectl create namespace loki
   helm upgrade --install loki --namespace=loki loki-stack-2.8.2.tgz  --set grafana.enabled=true
   
   
   // 只安装 Loki 和 promtail
   helm install loki ./loki-stack --namespace=loki --create-namespace
   ```

   

3. 获取密码登录

   ```
   kubectl get secret --namespace loki loki-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
   
   ```

4. 访问

   ```shell
   kubectl port-forward --address 0.0.0.0 --namespace loki service/loki-grafana 3000:80
   ```




检查 loki 的状态

```
curl -G -s "http://10.101.32.33:30389/loki/api/v1/label" | jq .
```

## 多集群 Loki 方案

### 一主多备

主要思路来自 [issue](https://github.com/grafana/loki/issues/5948)

![image-20220912085452061](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20220912085452061.png)

 `promtail` 不仅向本集群 Loki 发送日志，也向主集群 Loki 发送日志。

![image-20220912085928750](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20220912085928750.png)

### 单主

所有集群的 promtail  只向主集群发送日志

![image-20220912090036641](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20220912090036641.png)





##  参考文档

1. https://github.com/grafana/loki/issues/1866
2. https://github.com/grafana/loki/issues/5948
3. [K8s 日志架构](https://kubernetes.io/zh-cn/docs/concepts/cluster-administration/logging/)
4. PLG 实现 Kubernetes Pod 日志收集和展示 https://cloud.tencent.com/developer/article/1915207?from=article.detail.1941023
5. [Loki 使用系列](https://mp.weixin.qq.com/mp/appmsgalbum?action=getalbum&__biz=MzU4MjQ0MTU4Ng==&scene=1&album_id=1851417660249407499&count=3#wechat_redirect)
6. Loki生产环境集群方案  https://cloud.tencent.com/developer/article/1837819?from=article.detail.1941023



## 遗留问题

1. 有些节点的 promtail 健康检查一直失败。

   主要原因是，/var/log/pods/ 目录里面的日志 都是软链接，导致 promtail 收集不到日志。

   ![image-20220912093848062](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20220912093848062.png)

2. 微服务和简单可扩展模式中的 Gateway pods 起不来。

   

3. helm 部署 Loki 怎么增加自定义标签。

4. 主 Loki模式 和 多主模式 那个更优。

 　
