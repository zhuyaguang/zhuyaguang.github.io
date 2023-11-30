---
title: "在 KubeSphere 上部署最新版的 KubeEdge"
date: 2023-11-07T11:03:15+08:00
draft: true
description: "KubeEdge 安装使用笔记"
---

<!--more-->

### 准备

1. 一个 k8s 集群

   ```
   ./kk create config --with-kubernetes v1.26.0 --with-kubesphere
   
   
   ./kk create cluster -f config-sample.yaml
   ```

   

2. 一个 边缘节点 可以访问集群，contained 版本 >=1.6 

3. 边缘节点 kubelet kubectl 



#### 卸载 docker 安装contained

卸载

```shell
systemctl stop docker
systemctl stop docker.socket
systemctl stop containerd

yum list installed | grep docker

yum -y remove containerd.io.x86_64 \
              docker-ce.x86_64 \
              docker-ce-cli.x86_64 \
              docker-ce-rootless-extras.x86_64 \
              docker-compose-plugin.x86_64 \
              docker-scan-plugin.x86_64 \
							docker-buildx-plugin.x86_64
							

```

安装最新版

```shell
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

sudo yum install docker-ce docker-ce-cli containerd.io
```



### 安装 CloudCore

```shell
keadm init --advertise-address="10.108.96.16" --set cloudCore.service.enable=true --profile version=v1.14.0 --kube-config=/root/.kube/config
```



### 安装 EdgeCore

1. 安装 kubelet kubectl

   [添加yum源并安装kubectl/kubeadm/kubelet组件](https://blog.csdn.net/qq_14910065/article/details/132069986)

   ```shell
   yum install kubectl.x86_64 kubelet.x86_64 
   ```

2. 纳管 边缘节点

   ```shell
   keadm  join --cloudcore-ipport=10.108.96.16:10000 --token=39c24e241019083090b68f0d7bac101ba870d52526d5d7b7b881ee261ad3ac67.eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2OTk0MTA0Nzd9.rwdvDRBfU1hhzjCRoNzKhjNGx_aoVkC7U6tsYLfHP6w --kubeedge-version=1.15.0 --runtimetype=remote  --with-mqtt=false
   ```







我的博客即将同步至腾讯云开发者社区，邀请大家一同入驻：https://cloud.tencent.com/developer/support-plan?invite_code=1wjhqgxhgrr3u
