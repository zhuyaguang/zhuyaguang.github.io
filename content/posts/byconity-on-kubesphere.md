---
title: "Byconity on Kubesphere"
date: 2023-08-09T15:00:54+08:00
draft: true
---

# 基于 KubeSphere 搭建生产级云原生数仓 ByConity 

## 环境准备

### 1.  K8s 环境

我这里主要推荐 kubesphere 来部署 k8s 环境。为啥呢？

安装简单，简单三步就可以部署一个高可用的 k8s 环境

* 下载 KubeKey

```shell
export KKZONE=cn
curl -sfL https://get-kk.kubesphere.io | VERSION=v3.0.2 sh -
```

* 创建并配置集群文件

```shell
./kk create config config.yaml
```

编辑 config.yaml ，添加节点的 IP 、用户名、密码，并指定节点的角色

![image-20230809184804017](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20230809184804017.png)

* 创建集群

  ```shell
  ./kk create cluster -f config.yaml
  ```



以上步骤有问题可以参考 [kubesphere 官方文档](https://www.kubesphere.io/zh/docs/v3.3/installing-on-linux/introduction/multioverview/)



还有一个原因就是，颜值高，可以方便管理应用。

下面是 ByConity 部署的所有的工作负载，包括 deployment、statefulset ，都可以方便查看。

![image-20230809185123419](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20230809185123419.png)

![image-20230809185206530](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20230809185206530.png)



### 2、配置存储

kubesphere 的集群安装好之后，默认有一个 local 的 storageClass

![image-20230809190322941](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20230809190322941.png)

 

需要 将 chart 包 中 [value.yaml](https://github.com/ByConity/byconity-deploy/blob/master/examples/k8s/values.yaml) 中 **所有** 的 storageClassName 由 ``openebs-hostpath``  替换成 `local`



## 环境部署

有了 k8s 集群，现在要做的是就是 利用 helm 来部署 ByConity 了。

因为上一个步骤中，部署 kubesphere 过程中，会自动给你安装一个 helm ,所以这一步就不用安装 helm 了，如果你是用 kind 或者其他方式部署的 k8s ，记得手动安装 helm

### 第零步 下载 chart 包

```shell
git clone https://github.com/ByConity/byconity-deploy.git
cd byconity-deploy
```



### 第一步 部署 fdb-operator

```shell
helm upgrade --install --create-namespace --namespace byconity -f ./examples/k8s/values.yaml byconity ./chart/byconity --set fdb.enabled=false
```



byconity-fdb-operator running 后开启第二步操作

![image-20230809173246296](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20230809173246296.png)

### 第二步 部署服务

```shell
helm upgrade --install --create-namespace --namespace byconity -f ./examples/k8s/values.yaml byconity ./chart/byconity --set fdb.enabled=false
```



![image-20230809182438437](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20230809182438437.png)



看到 pod 都 running 起来，说明就部署成功了，我们进去 byconity-server 里面试试功能。

![image-20230809182954602](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20230809182954602.png)



## 布署工具的使用感受&评价

整个过程整体还是比较顺利的，有几个地方需要注意下

* 手动拉取镜像

   fdb-operator pod 要 running 的话，依赖 4 个镜像，所以一直没有起来，需要到其对应节点，手动拉取。

```
docker pull foundationdb/foundationdb-kubernetes-sidecar:6.2.30-1

docker pull foundationdb/foundationdb-kubernetes-sidecar:6.3.23-1

docker pull foundationdb/foundationdb-kubernetes-sidecar:7.1.15-1

docker pull foundationdb/fdb-kubernetes-operator:v1.9.0

docker pull byconity/byconity:0.1.0-GA
```

* 手动清理 PVC

  在 配置存储 步骤中，如果你 忘记 一两个 替换 storageClass ，需要你卸载 ByConity

  ```shell
  helm uninstall --namespace byconity byconity
  ```

  同时要清理 错误的 PVC

  ```shell
  kubectl delete pvc {pvcname} -n byconity
  ```

  

## 发现问题

部署过程中，发现 byconity-server-0 健康检查一直失败。根据日志 发现是 ipv6 的支持问题，将 ：： 改成 0.0.0.0 就可以了。

issue地址 ：https://github.com/ByConity/ByConity/issues/593
