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
   docker run --name loki -d -v /data/loki/config :/mnt/config -p 3100:3100 grafana/loki:2.6.1 -config.file=/mnt/config/loki-config.yaml
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











##  参考文档

1. https://github.com/grafana/loki/issues/1866
2. https://github.com/grafana/loki/issues/5948





 　
