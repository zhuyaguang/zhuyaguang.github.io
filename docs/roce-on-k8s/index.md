# RoCe on K8s 实践


## 部署 k8s 集群

* 选择 合适的 容器网络

## 部署 k8s-device-plugin

选择最新的版本

* https://github.com/NVIDIA/k8s-device-plugin

  

## 部署 RDMA 插件



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
    #   nodeSelector:
    #     aliyun.accelerator/rdma: "true"
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



### 测试

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: rdma-test-pod
spec:
  restartPolicy: OnFailure
  containers:
  - image: mellanox/centos_7_4_mofed_4_2_1_2_0_0_60
    name: mofed-test-ctr
    securityContext:
      capabilities:
        add: [ "IPC_LOCK" ]
    resources:
      limits:
        rdma/hca: 1
    command:
    - sh
    - -c
    - |
      ls -l /dev/infiniband /sys/class/net
      sleep 1000000
---

apiVersion: v1
kind: Pod
metadata:
  name: rdma-test-pod-1
spec:
  restartPolicy: OnFailure
  containers:
  - image: mellanox/centos_7_4_mofed_4_2_1_2_0_0_60
    name: mofed-test-ctr
    securityContext:
      capabilities:
        add: [ "IPC_LOCK" ]
    resources:
      limits:
        rdma/hca: 1
    command:
    - sh
    - -c
    - |
      ls -l /dev/infiniband /sys/class/net
      sleep 1000000
```


