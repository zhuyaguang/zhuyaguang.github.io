# 通过cadvistor在Kubeedge监控边缘节点pod信息


##  KubeEdge 监控三部曲：通过cadvistor在Kubeedge监控边缘节点pod信息

KubeEdge 上的监控，之前我们已经实现了通过 Node-exporter 实现节点信息监控，通过 gpu-exporter 实现GPU的监控，最后还有两个没有实现：1、边缘节点的 pod 信息没有监控 2、对于物理机，没有安装容器的机器，实现节点监控。

可以查看之前的博文：

[使用 Prometheus 监控 KubeEdge 边缘节点](https://zhuyaguang.github.io/kubeedge-on-prometheus/)

[使用 Prometheus 在 kubesphere 上监控 kubeedge 边缘节点（Jetson） CPU、GPU 状态](https://zhuyaguang.github.io/prometheus-jetson-on-kubeedge-in-kubesphere/)

![image-20250123152519472](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20250123152519472.png)

### 1、部署cadvisor，并接入prometheus


用下面的yaml，部署ServiceAccount、DaemonSet、Service、ServiceMonitor



```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    app.kubernetes.io/component: exporter
    app.kubernetes.io/name: cadvisor-exporter
    app.kubernetes.io/part-of: kube-prometheus
    app.kubernetes.io/version: 1.0.0
  name: cadvisor
  namespace: kubesphere-monitoring-system
```



```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  labels:
    app.kubernetes.io/component: exporter
    app.kubernetes.io/name: cadvisor-exporter
    app.kubernetes.io/part-of: kube-prometheus
    app.kubernetes.io/version: 1.0.0
  name: cadvisor
  namespace: kubesphere-monitoring-system
spec:
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app.kubernetes.io/component: exporter
      app.kubernetes.io/name: cadvisor-exporter
      app.kubernetes.io/part-of: kube-prometheus
  template:
    metadata:
      labels:
        app.kubernetes.io/component: exporter
        app.kubernetes.io/name: cadvisor-exporter
        app.kubernetes.io/part-of: kube-prometheus
        app.kubernetes.io/version: 1.0.0
    spec:
      containers:
        - image: tj.registry.com:5000/sys/cadvisor-arm64:v0.50.0
          imagePullPolicy: IfNotPresent
          name: cadvisor
          ports:
            - containerPort: 8080
              hostPort: 8080
              protocol: TCP
          resources: {}
          terminationMessagePath: /dev/termination-log
          terminationMessagePolicy: File
          volumeMounts:
            - mountPath: /rootfs
              name: root
            - mountPath: /var/run
              name: run
            - mountPath: /sys
              name: sys
            - mountPath: /var/lib/containerd
              name: containerd
            - mountPath: /etc/machine-id
              name: machineid
      dnsPolicy: ClusterFirst
      hostNetwork: true
      nodeName: star4-orin01
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      serviceAccount: cadvisor
      serviceAccountName: cadvisor
      terminationGracePeriodSeconds: 30
      tolerations:
        - effect: NoSchedule
          key: node-role.kubernetes.io/master
      volumes:
        - hostPath:
            path: /
            type: ""
          name: root
        - hostPath:
            path: /var/run
            type: ""
          name: run
        - hostPath:
            path: /sys
            type: ""
          name: sys
        - hostPath:
            path: /mnt/cubefs/registry/containerd
            type: ""
          name: containerd
        - hostPath:
            path: /etc/machine-id
            type: ""
          name: machineid
  updateStrategy:
    rollingUpdate:
      maxSurge: 0
      maxUnavailable: 1
    type: RollingUpdate

```



```yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app.kubernetes.io/component: exporter
    app.kubernetes.io/name: cadvisor-exporter
    app.kubernetes.io/part-of: kube-prometheus
    app.kubernetes.io/version: 1.0.0
  name: cadvisor-svc
  namespace: kubesphere-monitoring-system
spec:
  internalTrafficPolicy: Cluster
  ipFamilies:
    - IPv4
  ipFamilyPolicy: SingleStack
  ports:
    - name: metrics
      port: 8080
      protocol: TCP
      targetPort: 8080
  selector:
    app.kubernetes.io/component: exporter
    app.kubernetes.io/name: cadvisor-exporter
    app.kubernetes.io/part-of: kube-prometheus
  sessionAffinity: None
  type: ClusterIP
```



```yaml
apiVersion: v1
kind: Service
metadata:
  name: cadvisor-svc-nodeport
  namespace: kubesphere-monitoring-system
spec:
  ports:
  - port: 8080
    targetPort: 8080
    protocol: TCP
    nodePort: 32144
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 10800
  type: NodePort
  selector:
    app.kubernetes.io/component: exporter
    app.kubernetes.io/name: cadvisor-exporter
    app.kubernetes.io/part-of: kube-prometheus
```



```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  labels:
    app.kubernetes.io/component: exporter
    app.kubernetes.io/name: cadvisor-exporter
    app.kubernetes.io/part-of: kube-prometheus
    app.kubernetes.io/vendor: kubesphere
    app.kubernetes.io/version: 1.0.0
  name: cadvisor-exporter
  namespace: kubesphere-monitoring-system
spec:
  selector:
    matchLabels:
      app.kubernetes.io/component: exporter
      app.kubernetes.io/name: cadvisor-exporter
      app.kubernetes.io/part-of: kube-prometheus
  endpoints:
    - port: metrics
      interval: 10s
      honorLabels: true
```



然后就可以在Prometheus界面看到这个任务已经上线：



![](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/1731569090318-e280f0ed-ce59-4c89-836f-88958310a4a4.png)



也可以使用上面的nodeport svc 将cadvisor端口暴露出来，然后就可以登录cadvisor web界面

```plain
prometheus访问cadvisor的url：
http://10.107.104.8:32144/metrics

cadvisor的web界面：
http://10.107.104.8:32144/
```

### 2、界面显示监控信息

此时在kubesphere界面仍然无法显示edge节点上的pod的性能指标


抓包看，是因为：ks-apiserver查询Prometheus的时候，查询的是kubelet job里面的参数，但是自己部署的cadvisor job名是“cadvisor-svc”，所以查不出来。

报文：[query.pcap.txt](https://www.yuque.com/attachments/yuque/0/2024/txt/35101517/1731576524647-8f410f91-204e-4c1d-901d-15f2a252beb4.txt)（去掉后缀.txt后打开）

![](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/1731576285039-ae43b335-4bae-4a9e-95c9-f27dbc77943c.png)



跳过ks-apiserver，直接调用Prometheus，是可以查询出结果的



举例如下：

![](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/1731576431535-aa7821d5-f6be-42f6-885a-f20289f764cf.png)



其中query如下：

```plain
sum by (namespace, pod) (container_memory_working_set_bytes{job="cadvisor-svc", pod!="", image!=""}) * on (namespace, pod) group_left(owner_kind, owner_name) kube_pod_owner{} * on (namespace, pod) group_left(node) kube_pod_info{node="star4-orin01",pod=~"secspace|cadvisor-ncqtf|node-exporter-6srsh|dataagent-deployment-7fb44cc9c8-qgl8n|registry-ds-sfp4t|operator-deployment-7fc59c6c88-24v5l$"}
```

### 3、物理机部署node-exporter并接入K8S中的prometheus

部署环境为星上FPGA物理机。

#### 1、部署node-exporter

```
查看K8S中node-exporter的镜像的版本号，下载相同版本的二进制安装包
wget https://github.com/prometheus/node_exporter/releases/download/v1.3.1/node_exporter-1.3.1.linux-arm64.tar.gz

tar -xvzf  node_exporter-1.3.1.linux-arm64.tar.gz
cp node_exporter-1.3.1.linux-arm64/node_exporter /usr/local/bin/

启动node_exporter
node_exporter

即可访问
curl http://IP:9100/metrics
```

设置开机启动

参考：

[https://www.cnblogs.com/wal1317-59/p/12693309.html](https://www.cnblogs.com/wal1317-59/p/12693309.html)

[https://blog.csdn.net/shb_derek1/article/details/8489112](https://blog.csdn.net/shb_derek1/article/details/8489112)

```bash
#! /bin/sh
### BEGIN INIT INFO
# Provides:             spacecloud
# Required-Start:       
# Required-Stop:        
# Default-Start:        
# Default-Stop:         
# Short-Description:    spacecloud node-exporter
### END INIT INFO

nohup /usr/local/bin/node_exporter >/dev/null 2>&1 &
```

然后执行：

```bash
# 添加可执行权限
chmod +x /etc/init.d/node-exporter.sh
# 增加到rc列表中
cd /etc/init.d/
update-rc.d node-exporter.sh defaults 90

# 重启生效
reboot
```

若要去掉开机启动：

```bash
# 从rc列表中删除
cd /etc/init.d/
update-rc.d -f node-exporter.sh remove

# 删除脚本
rm /etc/init.d/node-exporter.sh

# 重启生效
reboot
```

#### 2、接入prometheus

参考：[https://segmentfault.com/a/1190000018940961](https://segmentfault.com/a/1190000018940961)

创建：Endpoints、Service、ServiceMonitor

```yaml
apiVersion: v1
kind: Endpoints
metadata:
  name: fpga-exporter
  namespace: kubesphere-monitoring-system
  labels:
    app.kubernetes.io/component: exporter
    app.kubernetes.io/name: fpga-exporter
    app.kubernetes.io/part-of: kube-prometheus
    app.kubernetes.io/version: 1.0.0
subsets:
- addresses:
  - ip: 10.15.40.160
  ports:
  - name: metrics
    port: 9100
    protocol: TCP
```

```yaml
apiVersion: v1
kind: Service
metadata:
  name: fpga-exporter
  namespace: kubesphere-monitoring-system
  labels:
    app.kubernetes.io/component: exporter
    app.kubernetes.io/name: fpga-exporter
    app.kubernetes.io/part-of: kube-prometheus
    app.kubernetes.io/version: 1.0.0
spec:
  type: ExternalName
  externalName: 10.15.40.160
  clusterIP: ""
  ports:
  - name: metrics
    port: 9100
    protocol: TCP
    targetPort: 9100
```

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: fpga-exporter
  namespace: kubesphere-monitoring-system
  labels:
    app.kubernetes.io/component: exporter
    app.kubernetes.io/name: fpga-exporter
    app.kubernetes.io/part-of: kube-prometheus
    app.kubernetes.io/vendor: kubesphere
    app.kubernetes.io/version: 1.0.0
spec:
  selector:
    matchLabels:
      app.kubernetes.io/component: exporter
      app.kubernetes.io/name: fpga-exporter
      app.kubernetes.io/part-of: kube-prometheus
  endpoints:
  - port: metrics
    interval: 10s
    honorLabels: true
```

然后将prometheus的svc端口暴露出来，下面的yaml新建了一个svc，通过nodeport的方式将prometheus的端口暴露出来：

```yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app.kubernetes.io/component: prometheus
    app.kubernetes.io/instance: k8s
    app.kubernetes.io/name: prometheus
    app.kubernetes.io/part-of: kube-prometheus
    app.kubernetes.io/version: 2.39.1
  name: prometheus-k8s-nodeport
  namespace: kubesphere-monitoring-system
spec:
  ports:
  - port: 9090
    targetPort: 9090
    protocol: TCP
    nodePort: 32143
  selector:
    app.kubernetes.io/component: prometheus
    app.kubernetes.io/instance: k8s
    app.kubernetes.io/name: prometheus
    app.kubernetes.io/part-of: kube-prometheus
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 10800
  type: NodePort
```

登录：

[http://10.11.140.110:32143/](http://10.11.140.110:32143/targets?search=fpga)

在prometheus的rule里面增加：

```
kubectl edit  prometheusrules.monitoring.coreos.com prometheus-k8s-rules -n kubesphere-monitoring-system

---
    - expr: |
        sum by (cpu, instance, job) (node_cpu_seconds_total{job="fpga-exporter",mode=~"user|nice|system|iowait|irq|softirq"})
      record: fpga_cpu_used_seconds_total
    - expr: |
        avg by (instance) (irate(fpga_cpu_used_seconds_total{job="fpga-exporter"}[5m]))
      record: node:fpga_cpu_utilisation:avg1m
---

这个规则是仿照下面的写的：

---
    - expr: |
        sum (node_cpu_seconds_total{job="node-exporter", mode=~"user|nice|system|iowait|irq|softirq"}) by (cpu, instance, job, namespace, pod, cluster)
      record: node_cpu_used_seconds_total
    - expr: |
        avg by (instance) (irate(fpga_cpu_used_seconds_total{job="fpga-exporter"}[5m]))
      record: node:fpga_cpu_utilisation:avg1m
---
```

之后就可以用node:fpga_cpu_utilisation:avg1m查询fpga的cpu使用率

