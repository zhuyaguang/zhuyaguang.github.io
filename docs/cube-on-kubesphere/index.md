# Cube on Kubesphere


# 基于kubesphere搭建一站式云原生机器学习平台 

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

  ```shell
  ./kk create cluster --with-kubernetes v1.18.8  --with-kubesphere v3.3.0
  ```

## 部署 cube-studio



### 部署注意事项

#### mysql  

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









## 使用 cube-studio

