---
title: "使用 Prometheus 监控 kubeedge 边缘节点 GPU 状态"
date: 2024-03-21T14:19:33+08:00
draft: true
---

## 环境部署

### 部署 k8s 环境

参考  [kubesphere 部署文档](https://kubesphere.io/zh/docs/v3.4/quick-start/all-in-one-on-linux/)

```
./kk create cluster --with-kubernetes v1.26.0 --with-kubesphere v3.4.1 --container-manager containerd
```

### 部署  KubeEdge 环境

参考 [在 KubeSphere 上部署最新版的 KubeEdge](https://zhuyaguang.github.io/kubeedge-install/)

| 组件       | 版本   |
| ---------- | ------ |
| kubesphere | 3.4.1  |
| containerd | 1.7.2  |
| k8s        | 1.26.0 |
| kubeedge   | 1.17.0 |

### 修改 kubesphere 配置

* 启动 kubeedge 功能

https://www.kubesphere.io/zh/docs/v3.3/pluggable-components/kubeedge/

* 修改 node-exporter 亲和性

* 安装 edgemesh

  https://blog.csdn.net/lovemxs/article/details/135240849

* 开启IptableManager

  https://blog.csdn.net/menghaocheng/article/details/128492427

### 安装 Jtop

###  安装 jetson GPU Exporter

https://blog.devops.dev/monitor-nvidia-jetson-gpu-82e256999840

### 使用 kubesphere  自定义监控

### 使用独立的 Grafana + Prometheus  监控

