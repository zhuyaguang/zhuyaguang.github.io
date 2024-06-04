---
title: "在 KubeSphere 上部署最新版的 KubeEdge"
date: 2023-11-07T11:03:15+08:00
draft: true
description: "KubeEdge 安装使用笔记"
---

<!--more-->

# 准备

1. 一个 k8s 集群，使用 kubesphere 安装

   ```shell
   centos
   
   ./kk create config --with-kubernetes v1.26.0 --with-kubesphere
   
   ./kk create cluster -f config-sample.yaml
   
    低版本的k8s:
    ./kk create cluster --with-kubernetes v1.22.12 --with-kubesphere v3.4.1
   
   
   ubuntu 20.04
   
   all in one 部署
   
   ./kk create cluster --with-kubernetes v1.26.0 --with-kubesphere v3.4.1 --container-manager containerd
   
   多节点 高可用部署
   
   ./kk create config --with-kubesphere 3.4.1 --with-kubernetes v1.26.0
   
   ./kk create cluster -f config-sample.yaml
   ```

   

2. 一个 边缘节点 可以访问集群，contained 版本 >=1.6  ，**如果是 docker 记得安装 CRI-dockerd**.



![image-20240110145607680](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20240110145607680.png)

### 可选：卸载 docker 安装contained

如果之前安装了 docker ,使用下面命令卸载

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



# 使用Keadm进行部署

Keadm 是一款用于安装 KubeEdge 的工具。 Keadm 不负责 K8s 的安装和运行,在使用它之前，请先准备好一个 K8s 集群。

KubeEdge 对 Kubernetes 的版本兼容性，更多详细信息您可以参考 [kubernetes-兼容性](https://github.com/kubeedge/kubeedge#kubernetes-compatibility) 来了解，以此来确定安装哪个版本的 Kubernetes 以及 KubeEdge。

## 使用限制

- `keadm` 目前支持 Ubuntu 和 CentOS OS。
- 需要超级用户权限（或 root 权限）才能运行。

## 设置云端（KubeEdge 主节点）

### keadm init

默认情况下边缘节点需要访问 cloudcore 中 `10000` ，`10002` 端口。 若要确保边缘节点可以成功地与集群通信，您需要创建防火墙规则以允许流量进入这些端口（10000 至 10004）。

**重要提示：**

1. 必须正确配置 kubeconfig 或 master 中的至少一个，以便可以将其用于验证 k8s 集群的版本和其他信息。
2. 请确保边缘节点可以使用云节点的本地 IP 连接云节点，或者需要使用 `--advertise-address` 标记指定云节点的公共 IP 。
3. `--advertise-address`（仅从 1.3 版本开始可用）是云端公开的地址（将添加到 CloudCore 证书的 SAN 中），默认值为本地 IP。
4. `keadm init` 将会使用二进制方式部署 cloudcore 为一个系统服务，如果您想实现容器化部署，可以参考 `keadm beta init` 。



### 安装 CloudCore

```shell
keadm init --advertise-address=10.108.96.24

// k8s 多节点的时候，配置 cloudcore 所在节点的地址

keadm init --advertise-address=10.101.32.14,10.101.32.15 --set cloudCore.service.enable=true --set cloudCore.hostNetWork=true --profile version=v1.14.0 --kube-config=/root/.kube/config

```

使用1.17.0版本 支持边缘Pods使用InClusterConfig访问Kube-APIServer 

```shell
keadm init --advertise-address=10.11.140.131,10.11.140.86 --set cloudCore.featureGates.requireAuthorization=true,cloudCore.modules.dynamicController.enable=true mosquitto.enable=false --kubeedge-version=v1.17.0
```



检查 cloudcore 是否安装成功

```shell
kubectl get pods -n kubeedge
```

卸载 CloudCore

```shell
keadm reset --kube-config=/root/.kube/config
```

## 设置太空端

### 安装最新版 containerd

```shell
centos

sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

sudo yum install  containerd.io

ubuntu

# Install containerd
apt-get update && apt-get install -y containerd

# Configure containerd
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml

# Restart containerd
systemctl restart containerd
```



### 安装 CNI 插件

```sh
mkdir -p /opt/cni/bin

tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.4.0.tgz

mkdir -p /etc/cni/net.d/

cat >/etc/cni/net.d/10-containerd-net.conflist <<EOF
{
  "cniVersion": "1.0.0",
  "name": "containerd-net",
  "plugins": [
    {
      "type": "bridge",
      "bridge": "cni0",
      "isGateway": true,
      "ipMasq": true,
      "promiscMode": true,
      "ipam": {
        "type": "host-local",
        "ranges": [
          [{
            "subnet": "10.88.0.0/16"
          }],
          [{
            "subnet": "2001:db8:4860::/64"
          }]
        ],
        "routes": [
          { "dst": "0.0.0.0/0" },
          { "dst": "::/0" }
        ]
      }
    },
    {
      "type": "portmap",
      "capabilities": {"portMappings": true}
    }
  ]
}
EOF

```

重启 containerd

````shell
systemctl daemon-reload

systemctl restart containerd

systemctl restart containerd.service
````



[CNI 安装参考链接](https://github.com/kubeedge/website/blob/e394dd0e0927fbe58b5d9cc80d94ba392241c859/i18n/zh/docusaurus-plugin-content-docs/current/faq/setup.md#unknown-service-runtimev1alpha2imageservice)



### 可选：安装 cri-dockerd(运行时为 docker )

* 下载 release 包

  https://github.com/Mirantis/cri-dockerd/releases

* 下载 cri-docker.service 和 cri-docker.socket

  https://github.com/Mirantis/cri-dockerd/tree/master/packaging/systemd

```
tar  zxvf cri-dockerd-0.3.9.arm64.tgz

cp cri-dockerd/cri-dockerd /usr/local/bin/cri-dockerd

cp cri-docker.service cri-docker.socket /etc/systemd/system/

sed -i -e 's,/usr/bin/cri-dockerd,/usr/local/bin/cri-dockerd,' /etc/systemd/system/cri-docker.service

systemctl daemon-reload
systemctl enable cri-docker.service
systemctl enable --now cri-docker.socket
```

* 重启 docker

  ```
  systemctl restart docker
  ```

### 安装 EdgeCore

**根据前面的准备步骤，安装 CNI CRI-dockerd**

1. 纳管 边缘节点

   containerd

   ```shell
   keadm  join --cloudcore-ipport=10.108.96.24:10000 --token=45055f5cd0eb033764cfb24ce4a5f64636862f7945efb174ff69eb437aafdfa9.eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3MTcxMjU1NDd9.YIgECHxVGU6Yq23zhMjAjPQ0TUOFWnMgqAQyQvdsaNM --kubeedge-version=1.15.1 --runtimetype=remote  --with-mqtt=false
   ```

   docker

   ```
   keadm  join --cloudcore-ipport=10.108.96.24:10000 --token=8cc6fc16618f8fc7b98a0221683b26d36a9b571c9257aac544574bb9dc014f74.eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3MTE2OTY4MTR9.EgxPs9Z5MFHSUxCwM9rvyY9XjWXBHKxZmezi7pzyOIo --kubeedge-version=1.15.1   --with-mqtt=false --remote-runtime-endpoint=unix:///var/run/cri-dockerd.sock
   ```

   

2. 查看状态

```shell
systemctl status edgecore
```

# 部署应用到边缘节点

部署 redis

```yaml
apiVersion: apps/v1 #  for k8s versions before 1.9.0 use apps/v1beta2  and before 1.8.0 use extensions/v1beta1
kind: Deployment
metadata:
  name: redis-master
spec:
  selector:
    matchLabels:
      app: redis
      role: master
      tier: backend
  replicas: 1
  template:
    metadata:
      labels:
        app: redis
        role: master
        tier: backend
    spec:
      nodeName: node5
      containers:
      - name: master
        image: registry.k8s.io/redis:e2e  # or just image: redis
        resources:
          requests:
            cpu: 100m
            memory: 100Mi
        ports:
        - containerPort: 6379
```

部署 nginx

```yaml
apiVersion: apps/v1 #  for k8s versions before 1.9.0 use apps/v1beta2  and before 1.8.0 use extensions/v1beta1
kind: Deployment
metadata:
  name: redis-master
spec:
  selector:
    matchLabels:
      app: redis
      role: master
      tier: backend
  replicas: 1
  template:
    metadata:
      labels:
        app: redis
        role: master
        tier: backend
    spec:
      nodeName: jetpack513
      containers:
      - name: master
        image: registry.k8s.io/redis:e2e  # or just image: redis
        resources:
          requests:
            cpu: 100m
            memory: 100Mi
        ports:
        - containerPort: 6379
```

# 去掉 daemonset 部署在边缘节点上

* 给 master 节点打标签

kubectl label nodes **tjmaster**  master=true

* 编辑daemonset 

kubectl edit  daemonset calico-node  -n kube-system

kubectl edit  daemonset kube-proxy   -n kube-system

kubectl edit  daemonset nodelocaldns  -n kube-system

* 增加一个标签 master: “true”,没有标签就都加上。

![image-20240205141929456](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20240205141929456.png)

![image-20240205142617622](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20240205142617622.png)

# 查看太空端服务日志

1.开启日志

![image-20231226105650084](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20231226105650084.png)

2.重启 edgecore

service edgecore restart

# 问题汇总

[常见问题](https://github.com/kubeedge/website/blob/e394dd0e0927fbe58b5d9cc80d94ba392241c859/i18n/zh/docusaurus-plugin-content-docs/current/faq/setup.md#unknown-service-runtimev1alpha2imageservice):

* CNI 网络问题，安装CNI插件，后重启。

  [安装脚本地址](https://github.com/containerd/containerd/blob/main/script/setup/install-cni)

  ![image-20231215085829040](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20231215085829040.png)

  1. `ctr -n k8s.io t ls`, 如果有残留的task，请执行`ctr -n k8s.io t kill {task id}`清理
  2. `ctr -n k8s.io c ls`, 如果有残留的容器，请执行`ctr -n k8s.io c rm {container id}`清理
  3. 执行`systemctl restart containerd.service`重启containerd

* Cgroup driver 

   删掉这行![image-20231225164747055](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20231225164747055.png)

* netstat -anpt |grep 10002 查看 cloudcore 是否能部署在这上面

* 注意 边缘节点的node id 和 cloud 节点名字不能重复

* can't mount rootfs的问题

  ![image-20240130092813051](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20240130092813051.png)
  
   修改 containerd 的配置
  
  ![image-20240130092843639](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20240130092843639.png)
  
* 220 上部署 containerd 问题比较多，换成 docker 需要安装  cri-dockerd。使用 cri-dockerd 的时候，keadm join 的时候 记得加上参数 --remote-runtime-endpoint=unix:///var/run/cri-dockerd.sock





更多问题可以访问[kubeedge FAQ ](https://github.com/kubeedge/website/blob/e394dd0e0927fbe58b5d9cc80d94ba392241c859/i18n/zh/docusaurus-plugin-content-docs/current/faq/setup.md#unknown-service-runtimev1alpha2imageservice)



