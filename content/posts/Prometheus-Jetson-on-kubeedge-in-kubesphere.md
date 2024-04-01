---
title: "使用 Prometheus 在 kubesphere 上监控 kubeedge 边缘节点（Jetson） GPU 状态"
date: 2024-03-21T14:19:33+08:00
draft: true
---

## 环境部署

> k8s containerd  / nvidia GPU  / Jetson  像一个永远不可能三角形

| 组件       | 版本                               |
| ---------- | ---------------------------------- |
| kubesphere | 3.4.1                              |
| containerd | 1.7.2                              |
| k8s        | 1.26.0                             |
| kubeedge   | 1.15.1                             |
| Jetson型号 | NVIDIA Jetson Xavier NX (16GB ram) |
| Jtop       | 4.2.7                              |
| JetPack    | 5.1.3-b29                          |
| Docker     | 24.0.5                             |

### 部署 k8s 环境

参考  [kubesphere 部署文档](https://kubesphere.io/zh/docs/v3.4/quick-start/all-in-one-on-linux/)

```
//  all in one 方式部署一台 单 master 的 k8s 集群

./kk create cluster --with-kubernetes v1.26.0 --with-kubesphere v3.4.1 --container-manager containerd
```

### 部署  KubeEdge 环境

参考 [在 KubeSphere 上部署最新版的 KubeEdge](https://zhuyaguang.github.io/kubeedge-install/)，部署kubeedge。

####  开启 边缘节点日志查询功能

1. vim /etc/kubeedge/config/edgecore.yaml

2. enable=true

   ![image-20231226105650084](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20231226105650084.png)



### 修改 kubesphere 配置

#### 1.开启 kubeedge 边缘节点插件

1. 修改 configmap--ClusterConfiguration

![image.png](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/1710467730006-6c1d70a7-23e5-4e3a-89b3-b0ad8bf39673.png)

2.  advertiseAddress 设置为 cloudhub 所在的物理机地址

![image.png](https://cdn.nlark.com/yuque/0/2024/png/35101517/1710467882107-c44e734b-245d-446b-8564-f8830e5db478.png#averageHue=%23374154&clientId=ubfbc51a9-8b9e-4&from=paste&height=755&id=u65c0d477&originHeight=755&originWidth=1189&originalType=binary&ratio=1&rotation=0&showTitle=false&size=56006&status=done&style=none&taskId=u689a8677-8a5b-43af-8592-e88e368b176&title=&width=1189)



[官方参考链接](https://www.kubesphere.io/zh/docs/v3.3/pluggable-components/kubeedge/)

> 修改完 发现可以显示边缘节点，但是没有 CPU 和 内存信息，发现边缘节点没有 node-exporter 这个pod。

![image-20240329112326949](C:\Users\DELL\AppData\Roaming\Typora\typora-user-images\image-20240329112326949.png)



#### 2. 修改 node-exporter 亲和性

`kubectl get ds -n kubesphere-monitoring-system` 发现 不会部署到边缘节点上

![image-20240329135414326](C:\Users\DELL\AppData\Roaming\Typora\typora-user-images\image-20240329135414326.png)

修改为：

```yaml
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: node-role.kubernetes.io/edgetest  -- 暂时修改了这里
                operator: DoesNotExist
```

node-exporter 是部署在边缘节点上了，但是 pods 起不来。

kubecrl edit该失败的pod，发现是其中的kube-rbac-proxy这个container启动失败，看这个container的logs。

发现是kube-rbac-proxy想要获取KUBERNETES_SERVICE_HOST和KUBERNETES_SERVICE_PORT这两个环境变量，但是获取失败，所以启动失败。

在K8S的集群中，当创建pod时，会在pod中增加KUBERNETES_SERVICE_HOST和KUBERNETES_SERVICE_PORT这两个环境变量，用于pod内的进程对kube-apiserver的访问，但是在kubeedge的edge节点上创建的pod中，这两个环境变量存在，但它是空的。

跟华为kubeedge的开发人员咨询，他们说会在kubeedge 1.17版本上增加这两个环境变量的设置。参考如下：
[https://github.com/wackxu/kubeedge/blob/4a7c00783de9b11e56e56968b2cc950a7d32a403/docs/proposals/edge-pod-list-watch-natively.md](https://github.com/wackxu/kubeedge/blob/4a7c00783de9b11e56e56968b2cc950a7d32a403/docs/proposals/edge-pod-list-watch-natively.md)

另一方面，他推荐安装edgemesh，安装之后在edge的pod上就可以访问kubernetes.default.svc.cluster.local:443了。

#### 3. edgemesh部署

1. 配置 cloudcore configmap

   `kubectl edit cm cloudcore -n kubeedge`   设置 dynamicController=true.

   修改完 重启 cloudcore `kubectl delete pod cloudcore-776ffcbbb9-s6ff8 -n kubeedge`

2. 配置 edgecore 模块，metaServer=true clusterDNS  

   ```shell
   $ vim /etc/kubeedge/config/edgecore.yaml
   
   modules:
     ...
     metaManager:
       metaServer:
         enable: true   //配置这里
   ...
   
   modules:
     ...
     edged:
       ...
       tailoredKubeletConfig:
         ...
         clusterDNS:
         - 169.254.96.16
   ...
   
   //重启edgecore
   $ systemctl restart edgecore
   ```

   ![image-20240329152628525](C:\Users\DELL\AppData\Roaming\Typora\typora-user-images\image-20240329152628525.png)

   

   

   修改完 验证是否修改成功

   ```
   $ curl 127.0.0.1:10550/api/v1/services
   
   {"apiVersion":"v1","items":[{"apiVersion":"v1","kind":"Service","metadata":{"creationTimestamp":"2021-04-14T06:30:05Z","labels":{"component":"apiserver","provider":"kubernetes"},"name":"kubernetes","namespace":"default","resourceVersion":"147","selfLink":"default/services/kubernetes","uid":"55eeebea-08cf-4d1a-8b04-e85f8ae112a9"},"spec":{"clusterIP":"10.96.0.1","ports":[{"name":"https","port":443,"protocol":"TCP","targetPort":6443}],"sessionAffinity":"None","type":"ClusterIP"},"status":{"loadBalancer":{}}},{"apiVersion":"v1","kind":"Service","metadata":{"annotations":{"prometheus.io/port":"9153","prometheus.io/scrape":"true"},"creationTimestamp":"2021-04-14T06:30:07Z","labels":{"k8s-app":"kube-dns","kubernetes.io/cluster-service":"true","kubernetes.io/name":"KubeDNS"},"name":"kube-dns","namespace":"kube-system","resourceVersion":"203","selfLink":"kube-system/services/kube-dns","uid":"c221ac20-cbfa-406b-812a-c44b9d82d6dc"},"spec":{"clusterIP":"10.96.0.10","ports":[{"name":"dns","port":53,"protocol":"UDP","targetPort":53},{"name":"dns-tcp","port":53,"protocol":"TCP","targetPort":53},{"name":"metrics","port":9153,"protocol":"TCP","targetPort":9153}],"selector":{"k8s-app":"kube-dns"},"sessionAffinity":"None","type":"ClusterIP"},"status":{"loadBalancer":{}}}],"kind":"ServiceList","metadata":{"resourceVersion":"377360","selfLink":"/api/v1/services"}}
   
   ```

   3. 安装 edgemesh

      ```
      git clone https://github.com/kubeedge/edgemesh.git
      cd edgemesh
      
      kubectl apply -f build/crds/istio/
      
      kubectl apply -f build/agent/resources/
      ```

      ![image-20240329154436074](C:\Users\DELL\AppData\Roaming\Typora\typora-user-images\image-20240329154436074.png)

#### 4. 修改dnsPolicy

edgemesh部署完成后，edge节点上的node-exporter中的两个境变量还是空的，也无法访问kubernetes.default.svc.cluster.local:443，原因是该pod中的dns服务器配置错误，应该是169.254.96.16的，但是却是跟宿主机一样的dns配置。

```shell
root@master1:/home/wpx/edgemesh-1.12.0/build/crds/istio# kubectl exec -it node-exporter-hcmfg -n kubesphere-monitoring-system -- sh
Defaulted container "node-exporter" out of: node-exporter, kube-rbac-proxy
/ $ cat /etc/resolv.conf 
nameserver 127.0.0.53
```

将dnsPolicy修改为ClusterFirstWithHostNet，之后重启node-exporter，dns的配置正确

      dnsPolicy: ClusterFirstWithHostNet
      hostNetwork: true



#### 5. 添加环境变量

vim /etc/systemd/system/edgecore.service

![image-20240329155133337](C:\Users\DELL\AppData\Roaming\Typora\typora-user-images\image-20240329155133337.png)

```
Environment=METASERVER_DUMMY_IP=kubernetes.default.svc.cluster.local
Environment=METASERVER_DUMMY_PORT=443
```

修改完重启 edgecore

```
systemctl daemon-reload
systemctl restart edgecore
```



**node-exporter 变成 running**!!!!

在边缘节点 `curl http://127.0.0.1:9100/metrics`  可以发现 采集到了边缘节点的数据。

最后我们可以将 kubesphere 的k8s 服务暴露出来，访问下看看是否能收集到 边缘节点采集的数据。



####  6. ipvs 改成 iptables 



![image-20240329170702278](C:\Users\DELL\AppData\Roaming\Typora\typora-user-images\image-20240329170702278.png)



至此 node



![image-20240329170803288](C:\Users\DELL\AppData\Roaming\Typora\typora-user-images\image-20240329170803288.png)







### 监控 GPU 状态

升级内核

安装 Jtop

###  安装 jetson GPU Exporter

https://blog.devops.dev/monitor-nvidia-jetson-gpu-82e256999840

容器化部署  jetson GPU Exporter 

### 使用 kubesphere  自定义监控

### 使用独立的 Grafana + Prometheus  监控

