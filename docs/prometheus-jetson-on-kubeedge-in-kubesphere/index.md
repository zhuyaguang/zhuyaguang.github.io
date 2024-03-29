# 使用 Prometheus 在 kubesphere 上监控 kubeedge 边缘节点（Jetson） GPU 状态


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
| kubeedge   | 1.15.1 |

### 修改 kubesphere 配置

* 由于 kubeedge 在 arm 上的服务发现功能不太好用，我们需要把 kubeproxy 的 ipvs 改成 iptables 

* 启动 kubeedge 功能

https://www.kubesphere.io/zh/docs/v3.3/pluggable-components/kubeedge/

* 修改 node-exporter 亲和性

* 安装 edgemesh

  https://blog.csdn.net/lovemxs/article/details/135240849

* 开启IptableManager

  https://blog.csdn.net/menghaocheng/article/details/128492427

### 安装 Jtop

### 升级内核

###  安装 jetson GPU Exporter

https://blog.devops.dev/monitor-nvidia-jetson-gpu-82e256999840

容器化部署  jetson GPU Exporter 

### 使用 kubesphere  自定义监控

### 使用独立的 Grafana + Prometheus  监控


