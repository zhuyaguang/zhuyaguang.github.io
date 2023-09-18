# RoCe on K8s 实践


## 部署 k8s 集群

* 选择 合适的 容器网络

## 部署 k8s-device-plugin

选择最新的版本

* https://github.com/NVIDIA/k8s-device-plugin

  

## 部署 RDMA 插件

### 方案一：使用阿里的镜像

来自文章：[在Kubernetes上使用RDMA](https://developer.aliyun.com/article/664961)

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: rdma-devices
  namespace: kube-system
data:
  config.json: |
    {
        "mode" : "hca"
    }

--- 
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: rdma-device-plugin
  namespace: kube-system
spec:
  selector:
    matchLabels:
      name: rdma-sriov-dp-ds
  template:
    metadata:
      annotations:
        scheduler.alpha.kubernetes.io/critical-pod: ""
      labels:
        name: rdma-sriov-dp-ds
    spec:
      hostNetwork: true
      tolerations:
      - key: CriticalAddonsOnly
        operator: Exists
      containers:
      - image: registry.cn-shanghai.aliyuncs.com/acs/rdma-device-plugin
        name: k8s-rdma-device-plugin
        imagePullPolicy: IfNotPresent
        securityContext:
          privileged: true
        volumeMounts:
          - name: device-plugin
            mountPath: /var/lib/kubelet/device-plugins
          - name: config
            mountPath: /k8s-rdma-sriov-dev-plugin
      volumes:
        - name: device-plugin
          hostPath:
            path: /var/lib/kubelet/device-plugins
        - name: config
          configMap:
            name: rdma-devices
            items:
            - key: config.json
              path: config.json
```



### 结论 

镜像版本太老了，而且没有 device plugin 的源代码，无法维护。但是设置 hostNetwork pod 是可以 running 起来的，节点上也有 hca 资源。所以该方案不推荐！



### 方案二 k8s-rdma-shared-dev-plugin

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: rdma-devices
  namespace: kube-system
data:
  config.json: |
    {
        "periodicUpdateInterval": 300,
        "configList": [
           {
             "resourceName": "hca_shared_devices_b",
             "rdmaHcaMax": 500,
             "selectors": {
               "deviceIDs": ["101b"]
             }
           }
        ]
    }

---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: rdma-shared-dp-ds
  namespace: kube-system
spec:
  selector:
    matchLabels:
      name: rdma-shared-dp-ds
  template:
    metadata:
      labels:
        name: rdma-shared-dp-ds
    spec:
      hostNetwork: true
      priorityClassName: system-node-critical
      containers:
      - image: ghcr.io/mellanox/k8s-rdma-shared-dev-plugin
        name: k8s-rdma-shared-dp-ds
        imagePullPolicy: IfNotPresent
        securityContext:
          privileged: true
        volumeMounts:
          - name: device-plugin
            mountPath: /var/lib/kubelet/
          - name: config
            mountPath: /k8s-rdma-shared-dev-plugin
          - name: devs
            mountPath: /dev/
      volumes:
        - name: device-plugin
          hostPath:
            path: /var/lib/kubelet/
        - name: config
          configMap:
            name: rdma-devices
            items:
            - key: config.json
              path: config.json
        - name: devs
          hostPath:
            path: /dev/
```



> 上面配置中，"deviceIDs": ["101b"] 通过  cat /sys/class/infiniband/mlx5_2/device/device 命令查出来。

如何判断，device plugin 安装成功呢，describe node 发现资源挂载成功就可以了

![image-20230821142528961](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20230821142528961.png)



### 方案二 测试

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: mofed-test-pod
spec:
  restartPolicy: OnFailure
  nodeName: 10.106.124.3
  hostNetwork: true
  containers:
  - image: mellanox/rping-test
    name: mofed-test-ctr
    securityContext:
      capabilities:
        add: [ "IPC_LOCK" ]
    resources:
      limits:
        rdma/hca_shared_devices_b: 1
    command:
    - sh
    - -c
    - |
      ls -l /dev/infiniband /sys/class/infiniband /sys/class/net
      sleep 1000000

---
apiVersion: v1
kind: Pod
metadata:
  name: mofed-test-pod2
spec:
  restartPolicy: OnFailure
  nodeName: 10.106.124.4
  hostNetwork: true
  containers:
  - image: mellanox/rping-test
    name: mofed-test-ctr
    securityContext:
      capabilities:
        add: [ "IPC_LOCK" ]
    resources:
      limits:
        rdma/hca_shared_devices_b: 1
    command:
    - sh
    - -c
    - |
      ls -l /dev/infiniband /sys/class/infiniband /sys/class/net
      sleep 1000000
```

* 测试命令1

```
ib\_read\_bw -q 30

ib\_read\_bw -q 30 10.106.156.3
```



![image-20230821142703589](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20230821142703589.png)



* 测试命令2

```
ib_write_bw -d mlx5_2  -F --report_gbits

ib_write_bw -d mlx5_2 -F --report_gbits 10.106.156.3
```



![image-20230821143421094](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20230821143421094.png)



![image-20230821171553969](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20230821171553969.png)

* 测试命令3

  ```
  ib_send_bw -d mlx5_3 -i 1 -R --report_gbits
  
  
  ib_send_bw -d mlx5_3 -i 1 -R --report_gbits 10.106.156.4
  ```

* 测试命令4

  ```
  ib_write_bw -d mlx5_3 -a -F
  
  ib_write_bw  -F -d mlx5_3 10.233.92.6 -D 10 --cpu_util --report_gbits
  ```

  

### 常用命令

* 查看存储 InfiniBand 设备节点的目录

  ls /dev/infiniband/

* 查看网卡

  ibdev2netdev   

* 查询网卡 IP

  ip a show dev enp88s0

* 查看设备ID

  cat /sys/class/infiniband/mlx5_bond_0/device/device

  cat /sys/class/infiniband/mlx5_2/device/device

*  查看网卡型号

  `lspci -s 0000:17:00.0`

![image-20230821113834360](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20230821113834360.png)

* 查看设备和网卡

  ls -la /dev/infiniband /sys/class/net

* 查询 InfiniBand（IB）设备的状态和配置信息

  ibv_devinfo

## 参考文档

[k8s RoCE 部署: k8s-rdma-shared-dev-plugin + macvlan cni](https://blog.csdn.net/sunshuying1010/article/details/124951208)

[在Kubernetes上使用RDMA](https://developer.aliyun.com/article/664961)



### device plugin 

https://github.com/Mellanox/k8s-rdma-shared-dev-plugin 推荐

**https://github.com/k8snetworkplumbingwg/sriov-network-device-plugin** 牛哥使用的，star数最高

https://github.com/hustcat/k8s-rdma-device-plugin



### Nvidia 文档

https://docs.nvidia.com/networking/display/COKAN10/K8s+on+Bare+Metal+-+Ethernet#

https://docs.nvidia.com/networking/category/solutions





## deepspeed 训练方案

### 安装 arena

[下载链接](https://github.com/kubeflow/arena/releases)

```shell
tar -xvf arena-installer.tar.gz 

cd arena-installer

./install.sh
```



### 安装存储

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: training-data-pv
  labels:
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/data"
    
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: training-data
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 3Gi
```



### 构建训练镜像

```dockerfile
From registry.cn-beijing.aliyuncs.com/acs/deepspeed:v072_base

# Install OpenSSH
RUN apt-get install -y --no-install-recommends openssh-client openssh-server && \
    mkdir -p /var/run/sshd

# Allow OpenSSH to talk to containers without asking for confirmation
# by disabling StrictHostKeyChecking.
RUN sed -i 's/[ #]\(.*StrictHostKeyChecking \).*/ \1no/g' /etc/ssh/ssh_config && \
    echo "    UserKnownHostsFile /dev/null" >> /etc/ssh/ssh_config && \
    sed -i 's/#\(StrictModes \).*/\1no/g' /etc/ssh/sshd_config

RUN apt update
RUN apt install -y ninja-build
WORKDIR /workspace 
COPY DeepSpeedExamples .
```

### 提交训练任务

```shell
arena submit etjob \
    --name=deepspeed-helloworld \
    --gpus=1 \
    --workers=2 \
    --image=registry.cn-beijing.aliyuncs.com/acs/deepspeed:hello-deepspeed \
    --data=training-data:/data \
    --tensorboard \
    --logdir=/data/deepspeed_data \
    "deepspeed /workspace/DeepSpeedExamples/HelloDeepSpeed/train_bert_ds.py --checkpoint_dir /data/deepspeed_data"
```

```shell
arena submit etjob \
    --name=deepspeed-helloworld \
    --gpus=1 \
    --workers=3 \
    --image-pull-policy=IfNotPresent \
    --image=deepspeed:v3 \
    --data=training-data:/data \
    --tensorboard \
    --logdir=/data/deepspeed_data \
    "sleep 1000000000"
```



```shell
arena submit etjob \
    --name=deepspeed-helloworld \
    --gpus=1 \
    --workers=2 \
    --image=registry.cn-beijing.aliyuncs.com/acs/deepspeed:hello-deepspeed \
    --data=training-data:/data \
    --tensorboard \
    --logdir=/data/deepspeed_data \
    "sleep 1000000000"
```



![image-20230918090640213](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20230918090640213.png)



![image-20230918091618193](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20230918091618193.png)

> 任务启动后，有一个 launcher pod ，在 pod /job/hostfile 里面有 worker 节点的信息。 按道理讲，launcher pod 可以 直接 ssh 到 其他 worker 节点的。但是集群的 DNS 有问题，只能在  **launcher pod** 修改 hostsfile



![image-20230918091428675](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20230918091428675.png)



#### 启动任务

```shell
deepspeed --master_addr=10.244.125.229 --hostfile=/job/hostfile /benchmarks/communication/all_reduce.py --scan
```



```
Host deepspeed-helloworld-launcher
    Hostname 10.244.125.234
    Port 6001
    User root
Host deepspeed-helloworld-worker-0
    Hostname 10.244.125.233
    Port 6002
    User root
```













```

RDMA 接口和架构介绍

1. 双边操作 send

2. 单边操作 write/read/atomic

3. 内存管理机制

4. 队列机制

5. 重试与错误处理机制

RDMA 软件开发接口 libverbs

1. 四种传输方式

2. 内存管理

3. 发送与接收 API

4. 完成消息处理

5. 用 C 语言写一个 libverbs 的样例

用 Rust 异步开发 RDMA 应用 async-rdma
1. Rust 异步编程

2. async-rdma 的内存管理

3. async-rdma 对 ibverbs 的 API 封装

4. 用 Rust 语言写一个 RDMA 的样例

RDMA 内核模块

1. RDMA 网卡硬件接口

2. 软硬件接口设计和样例

3. 使用 C 语言写一个简单驱动样例

用 Rust 4 Linux 开发 RDMA 设备驱动

1. Rust 4 Linux 的介绍和样例

2. 使用 Rust 语言开发 RDMA 简单样例

硬件开发语言 Bluespec

1. Bluespec 与 SystemVerilog 的关系

2. 冲突矩阵与优先级

3. 基于 Bluespec 的流水线、状态机设计

RDMA 发送队列硬件实现

1. 发送队列流水线架构2. Controller 架构

3. DMA 出错处理

RDMA 接收队列硬件实现

1. 接收队列流水线架构

2. 错误请求处理

3. 重传处理

RDMA 响应处理硬件实现
1. 响应处理流水线架构

2. 错误响应处理

3. 重试响应处理

RDMA 其他功能硬件实现

1. 完成队列架构

2. 虚实地址转换处理

3. 元数据管理
```


