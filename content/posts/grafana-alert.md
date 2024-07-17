---
title: "Grafana Alert"
date: 2024-07-04T16:25:33+08:00
draft: true
---

## 部署 grafana

```
docker run -d -p 3000:3000 --name=grafana grafana/grafana-enterprise
```

## 告警规则

测试环境地址：http://10.11.140.85:3000/d/rYdddlPWk/node-exporter-full?orgId=1&refresh=1m

### 配置钉钉告警
添加联络点
![img_4.png](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/img_4.png)

配置联络点名称，类型，消息格式

![img_5.png](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/img_5.png)

### 配置告警规则
增加告警
![img.png](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/img.png)

填写告警内容

![img_1.png](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/img_1.png)

配置告警目录和持续时间

![img_2.png](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/img_2.png)

配置告警发送源

![img_3.png](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/img_3.png)
### 磁盘

磁盘使用率 > 80 %

```
100 * (1 - (node_filesystem_free_bytes{fstype=~"ext4|xfs"} / node_filesystem_size_bytes{fstype=~"ext4|xfs"})) > 80
```

### 内存

```
((1 - (node_memory_MemFree_bytes / node_memory_MemTotal_bytes)) * 100) > 50
```

### CPU

```
sum(rate(node_cpu_seconds_total{mode!="idle"}[5m])) by (instance) > 80
```

### GPU 

```
gpu_usage_gpu
```



### 配置采集的频率和采集的项目

```
kubectl -n kubesphere-monitoring-system edit prometheus k8s

evaluationInterval:5s
```



```
kubectl edit  ds node-exporter  -n kubesphere-monitoring-system

        - --collector.disable-defaults
        - --collector.cpu
        - --collector.cpufreq
        - --collector.diskstats
        - --collector.meminfo
        - --collector.filesystem
```



