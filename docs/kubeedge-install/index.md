# 在 KubeSphere 上部署最新版的 KubeEdge


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

# 使用Keadm进行部署

Keadm 是一款用于安装 KubeEdge 的工具。 Keadm 不负责 K8s 的安装和运行,在使用它之前，请先准备好一个 K8s 集群。

KubeEdge 对 Kubernetes 的版本兼容性，更多详细信息您可以参考 [kubernetes-兼容性](https://github.com/kubeedge/kubeedge#kubernetes-compatibility) 来了解，以此来确定安装哪个版本的 Kubernetes 以及 KubeEdge。



## 使用限制

- `keadm` 目前支持 Ubuntu 和 CentOS OS。RaspberryPi 的支持正在进行中。
- 需要超级用户权限（或 root 权限）才能运行。
- `keadm beta`功能在 v1.10.0 上线，如果您需要使用相关功能，请使用 v1.10.0 及以上版本的 keadm。



## 设置云端（KubeEdge 主节点）

### keadm init

默认情况下边缘节点需要访问 cloudcore 中 `10000` ，`10002` 端口。 若要确保边缘节点可以成功地与集群通信，您需要创建防火墙规则以允许流量进入这些端口（10000 至 10004）。

> `keadm init` 将安装并运行 cloudcore，生成证书并安装 CRD。它还提供了一个命令行参数，通过它可以设置特定的版本。不过需要注意的是：\ 在 v1.11.0 之前，`keadm init` 将以进程方式安装并运行 cloudcore，生成证书并安装 CRD。它还提供了一个命令行参数，通过它可以设置特定的版本。\ 在 v1.11.0 之后，`keadm init` 集成了 Helm Chart，这意味着 cloudcore 将以容器化的方式运行。\ 如果您仍需要使用进程的方式启动 cloudcore ，您可以使用`keadm deprecated init` 进行安装，或者使用 v1.10.0 之前的版本。

**重要提示：**

1. 必须正确配置 kubeconfig 或 master 中的至少一个，以便可以将其用于验证 k8s 集群的版本和其他信息。
2. 请确保边缘节点可以使用云节点的本地 IP 连接云节点，或者需要使用 `--advertise-address` 标记指定云节点的公共 IP 。
3. `--advertise-address`（仅从 1.3 版本开始可用）是云端公开的地址（将添加到 CloudCore 证书的 SAN 中），默认值为本地 IP。
4. `keadm init` 将会使用二进制方式部署 cloudcore 为一个系统服务，如果您想实现容器化部署，可以参考 `keadm beta init` 。

举个例子：



### 安装 CloudCore

```shell
keadm init --advertise-address=10.101.32.14,10.101.32.15 --set cloudCore.service.enable=true --set cloudCore.hostNetWork=true --profile version=v1.14.0 --kube-config=/root/.kube/config
```



卸载

```shell
keadm reset --kube-config=/root/.kube/config
```



### 安装 EdgeCore

1. 安装 kubelet kubectl

   [添加yum源并安装kubectl/kubeadm/kubelet组件](https://blog.csdn.net/qq_14910065/article/details/132069986)

   ```shell
   yum install kubectl.x86_64 kubelet.x86_64 
   ```

2. 纳管 边缘节点

   ```shell
   keadm  join --cloudcore-ipport=10.101.32.15:10000 --token=0ae1a6f88da72648900f581fe8c9d9e1d9555cc6033abe7d7864bfdd8b09f0ad.eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3MDI2MzM1Nzl9.V7Ug3i2Aey1DAeO05Lr0VpkeyGazEXJDNs7HxoY07LE --kubeedge-version=1.15.0 --runtimetype=remote  --with-mqtt=false
   ```





### 重启 containerd

```

systemctl daemon-reload

systemctl restart containerd
```





我的博客即将同步至腾讯云开发者社区，邀请大家一同入驻：https://cloud.tencent.com/developer/support-plan?invite_code=1wjhqgxhgrr3u

