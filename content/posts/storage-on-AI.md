---
title: "AI 场景下的分布式存储方案"
date: 2022-09-28T09:26:16+08:00
draft: false
description: "搭建机器学习的分布式存储环境"
---

<!--more-->

AI 训练的时候经常要拷贝数据集来训练，之前在前项目组发现是一人配一台性能比较好的台式机，然后就是共享几台 A100 的服务器。分布式存储的目的就是访问远程数据集就像访问本地磁盘一样方便、安全、速度快。目前在数据库赛道国产涌现了许多优秀作品。

下面就探索下 JuiceFS、Curve 

## JuiceFS

### JuiceFS 安装和简单使用

1. [下载客户端](https://www.juicefs.com/docs/zh/community/installation)

2. node1 创建文件系统

   ```shell
   juicefs format \
       --storage minio \
       --bucket http://10.101.32.11:9000/data \
       --access-key admin \
       --secret-key root123456 \
       redis://:zjlab123456@10.101.32.11:6379/1 \
       myjfs
   ```

3. 在 node2 挂载 

   ```shell
   juicefs mount redis://:zjlab123456@10.101.32.11:6379/1 ~/jfs
   ```

   这样 只要是挂载了的节点 /root/jfs 目录就是共享的了

### k8s 上使用

1. 使用 helm 安装 juicefs 的 CSI

   ```shell
   helm repo add juicefs-csi-driver https://juicedata.github.io/charts/
   helm repo update
   helm install juicefs-csi-driver juicefs-csi-driver/juicefs-csi-driver -n kube-system -f ./values.yaml
   ```

   Value.yaml 设置如下：

   ```yaml
   storageClasses:
   - name: juicefs-sc
     enabled: true
     reclaimPolicy: Retain
     backend:
       name: "zj-juicefs"
       metaurl: "redis://:zjlab123456@10.101.32.11:6379/1"
       storage: "minio"
       accessKey: "admin"
       secretKey: "root123456"
       bucket: "http://10.101.32.11:9000/data"
       # 如果需要设置 JuiceFS Mount Pod 的时区请将下一行的注释符号删除，默认为 UTC 时间。
       # envs: "{TZ: Asia/Shanghai}"
     mountPod:
       resources:
         limits:
           cpu: "1"
           memory: "1Gi"
         requests:
           cpu: "1"
           memory: "1Gi"
   ```

2. 使用 JuiceFS 为 Pod 提供存储

   ```yaml
   apiVersion: v1
   kind: PersistentVolumeClaim
   metadata:
     name: web-pvc
   spec:
     accessModes:
       - ReadWriteMany
     resources:
       requests:
         storage: 10Pi
     storageClassName: juicefs-sc
   ---
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: nginx-run
   spec:
     selector:
       matchLabels:
         app: nginx
     template:
       metadata:
         labels:
           app: nginx
       spec:
         containers:
           - name: nginx
             image: linuxserver/nginx
             ports:
               - containerPort: 80
             volumeMounts:
               - mountPath: /config
                 name: web-data
         volumes:
           - name: web-data
             persistentVolumeClaim:
               claimName: web-pvc
   ```

   这样我在 pod 里面创建了一个文件

   ![image-20220928101952530](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20220928101952530.png)

   另外一个节点就会同步：

   ![image-20220928102047619](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20220928102047619.png)

### 在 cube-studio 上改造原有的本地分布式存储为 JuiceFS

1. 以  jupyter 命名空间下的pods为例，先删除掉 原来的PV

```shell
kubectl delete  pv jupyter-kubeflow-archives
```

2. 创建新的 PV

   换掉 name labels volumeHandle 成 PV name 并保持一致

   增加 claimRef 部分，和 PVC 直接绑定

   accessModes 改成一致

   mountOptions 设置保存路径

   ```yaml
   cat <<EOF | kubectl apply -f -
   apiVersion: v1
   kind: PersistentVolume
   metadata:
     name: jupyter-kubeflow-archives
     labels:
       jupyter-pvname: jupyter-kubeflow-archives
   spec:
     capacity:
       storage: 500Gi
     volumeMode: Filesystem
     accessModes:
       - ReadWriteMany
     persistentVolumeReclaimPolicy: Retain
     claimRef:
       apiVersion: v1
       kind: PersistentVolumeClaim
       name: kubeflow-archives
       namespace: jupyter
     csi:
       driver: csi.juicefs.com
       volumeHandle: jupyter-kubeflow-archives
       fsType: juicefs
       nodePublishSecretRef:
         name: juicefs-sc-secret
         namespace: kube-system
       volumeAttributes:
         juicefs/mount-cpu-limit: 5000m
         juicefs/mount-memory-limit: 5Gi
         juicefs/mount-cpu-request: 1m
         juicefs/mount-memory-request: 1Mi
     mountOptions:
       - subdir=kubeflow/archives
   EOF
   ```

3. 这样就可以在 vscode 写的代码，可以保存到远端了。

   ![image-20220928104514440](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20220928104514440.png)

   另外一个节点就可以同步看到该文件了

   ![image-20220928105034910](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20220928105034910.png)
