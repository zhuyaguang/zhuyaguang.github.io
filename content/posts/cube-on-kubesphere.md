---
title: "基于 kubesphere 搭建一站式云原生机器学习平台 "
date: 2022-07-18T11:31:10+08:00
draft: false
description: "在 kubesphere 上搭建 cube-studio "
---

<!--more-->

# 基于 kubesphere 搭建一站式云原生机器学习平台 

## 搭建 kubesphere 

> 注意机器 最低规格为：8C16G  kubectl版本要1.24

* 卸载kubesphere，k8s版本太新有问题，会导致部分 CRD 不能安装

  ```shell
  ./kk delete cluster
  ```

* 清理 kubeconfig，不然会导致其他 node 节点 无法使用 kubectl

  ```shell
  rm -rf  /root/.kube/config
  ```

*  安装 1.18 版本的 k8s

  ```
  ./kk create cluster --with-kubernetes v1.18.8  --with-kubesphere v3.3.0
  ```

## 部署 cube-studio



### 部署注意事项

#### mysql  遇到的坑

*  标签未打成功

查看node标签

```shell
kubectl get nodes --show-labels
```

发现如果没有  mysql=true 标签，重新执行打标签命令

```shell
kubectl label node $node train=true cpu=true notebook=true service=true org=public istio=true knative=true kubeflow=true kubeflow-dashboard=true mysql=true redis=true monitoring=true logging=true --overwrite
```

* 手动拉取 busybox

如果  mysql 报错：

```shell
Warning Failed 34s kubelet Failed to pull image "busybox": rpc error: code = Unknown desc = Error response from daemon: Head "https://registry-1.docker.io/v2/library/busybox/manifests/latest": unauthorized: incorrect username or password
```

需要  docker login ，然后`docker pull busybox ` 手动拉取

* PV 雨 PVC 未绑定

`kubectl get pv infra-mysql-pv`  查看PV状态，如果未绑定添加 `storageClassName: local`等字段

`kubectl edit pv infra-mysql-pv`

```yaml
claimRef:
    apiVersion: v1
    kind: PersistentVolumeClaim
    name: infra-mysql-pvc
    namespace: infra
storageClassName: local
```

* 重启 mysql

`kubectl edit  deploy -n infra mysql` 设置 replicas=0

然后清理 `/data/k8s/infra/mysql` 残余数据

最后  replicas=1 坐等 infra 命名空间下面的 pod 都 running



#### notebook 遇到的坑

* 清空 kubeconfig

kubectl edit configmap kubernetes-config -n infra

kubectl edit configmap kubernetes-config -n pipeline

kubectl edit configmap kubernetes-config -n katib



## 使用 cube-studio



### 快速使用

* 创建项目，不要把用户都放在  public 项目组里面，会有问题。

* 修改仓库

如果是拉取 docker hub 上面的镜像的话，训练---仓库---hubsecret，修改你的 dockerhub 的用户名和密码

如果是拉取 Harbor 镜像，新建一个仓库，填写 Harbor 服务器郁闷和用户名密码

* 创建你的 任务 镜像

设置镜像的仓库，完成名称带上版本号。

你的镜像可以在开发环境上打好，然后上传到 Harbor 上。

* 创建 任务模版 

填写镜像，任务名称，启动命令







### 使用 GPU

* [安装 nvidia 驱动](https://wangjunjian.com/gpu/2020/11/03/install-nvidia-gpu-driver-on-ubuntu.html)
* [安装 nvidia-docker2](https://wangjunjian.com/docker/2020/10/18/install-nvidia-docker2-on-ubuntu.html)
* [Ubuntu18.04安装nvidia-docker2](https://www.cnblogs.com/l-hh/p/13451639.html)



### 安装 Harbor 并配置证书

  [Harbor在线安装：3分钟体验Harbor!](https://mp.weixin.qq.com/s/oj-C8ioIRfj9uYMDsDsA1w)

[How to install and use VMware Harbor private registry with Kubernetes](https://blog.inkubate.io/how-to-use-harbor-private-registry-with-kubernetes/)

[Pull an Image from a Private Registry](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/)



在 部署好的 Harbor 中添加 HTTPS 证书配置

[harbor镜像仓库-https访问的证书配置](https://zhuanlan.zhihu.com/p/234918875)

[x509: cannot validate certificate for 10.30.0.163 because it doesn't contain any IP SANs](https://blog.csdn.net/min19900718/article/details/87920254)



最后 Docker login $harborIP



### 使用BentozzMl快速发布一个 web 镜像



## 参考文档

* [腾讯音乐栾鹏：cube-studio开源一站式云原生机器学习平台](https://mp.weixin.qq.com/s/6uaUFS01W2lxnM-SU4PsfQ)

