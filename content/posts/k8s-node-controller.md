---
title: "实现一个controller 同步远程私有集群状态"
date: 2025-01-23T16:31:24+08:00
draft: true
---

## 实现一个controller 同步远程私有集群状态

### 背景

我们数据中心本地有一个私有的k8s集群，想在该集群的 Dashboard 上面实时监控另外一个集群的边缘节点。实现统一监控。

### 实现方案

目前已经实现了一个 controller 对节点的控制，需要在原来的代码逻辑上增加一个控制逻辑，通过 内网穿透 将远程私有集群的 6443 接口暴露出来到 阿里云的公网 IP上，然后本地  controller  通过 公网 IP：6443 接口获取节点信息，然后同步到本地集群。

所以第一步本地集群新建若干个 fake 节点与远程私有集群的保持一致。

#### 1、构建虚拟节点

```yaml
apiVersion: v1
kind: Node
metadata:
  annotations:
    node.alpha.kubernetes.io/ttl: "0"
    volumes.kubernetes.io/controller-managed-attach-detach: "true"
  labels:
    beta.kubernetes.io/arch: arm64
    beta.kubernetes.io/os: linux
    kubernetes.io/arch: arm64
    kubernetes.io/hostname: aman01
    kubernetes.io/os: linux
    node-role.kubernetes.io/agent: ""
    node-role.kubernetes.io/edge: ""
    machine.type: aman
    spacecloud.zhejianglab.cn/belonging-to: aman
    satellites: aman
    usage: aman
  name: aman01
spec:
  podCIDR: 192.168.2.0/24
  podCIDRs:
    - 192.168.2.0/24
  taints:
    - effect: NoSchedule
      key: node.kubernetes.io/unreachable
    - effect: NoExecute
      key: node.kubernetes.io/unreachable
status:
  addresses:
    - address: 192.168.***.***
      type: InternalIP
    - address: aman01
      type: Hostname
  daemonEndpoints:
    kubeletEndpoint:
      Port: 10351
  images:
    - names:
        - docker.io/library/algorithm-python:240912
      sizeBytes: 17788280435
  nodeInfo:
    architecture: arm64
    bootID: 2fd860f0-d1ee-4084-b072-7a18264ef901
    containerRuntimeVersion: containerd://1.7.2
    kernelVersion: 5.15.136-tegra
    kubeProxyVersion: v0.0.0-master+$Format:%H$
    kubeletVersion: v1.26.10-kubeedge-v0.0.0-master+$Format:%h$
    machineID: 5dbfb12414a3456d9014d88183e338b1
    operatingSystem: linux
    osImage: Ubuntu 22.04.4 LTS
    systemUUID: 5dbfb12414a3456d9014d88183e338b1
---
apiVersion: v1
kind: Node
metadata:
  annotations:
    node.alpha.kubernetes.io/ttl: "0"
    volumes.kubernetes.io/controller-managed-attach-detach: "true"
  labels:
    beta.kubernetes.io/arch: arm64
    beta.kubernetes.io/os: linux
    kubernetes.io/arch: arm64
    kubernetes.io/hostname: aman02
    kubernetes.io/os: linux
    node-role.kubernetes.io/agent: ""
    node-role.kubernetes.io/edge: ""
    machine.type: aman
    spacecloud.zhejianglab.cn/belonging-to: aman
    satellites: aman
    usage: aman
  name: aman02
spec:
  podCIDR: 192.168.2.0/24
  podCIDRs:
    - 192.168.2.0/24
  taints:
    - effect: NoSchedule
      key: node.kubernetes.io/unreachable
    - effect: NoExecute
      key: node.kubernetes.io/unreachable
status:
  addresses:
    - address: 192.168.***.***
      type: InternalIP
    - address: aman01
      type: Hostname
  daemonEndpoints:
    kubeletEndpoint:
      Port: 10351
  images:
    - names:
        - docker.io/library/algorithm-python:240912
      sizeBytes: 17788280435
  nodeInfo:
    architecture: arm64
    bootID: 2fd860f0-d1ee-4084-b072-7a18264ef901
    containerRuntimeVersion: containerd://1.7.2
    kernelVersion: 5.15.136-tegra
    kubeProxyVersion: v0.0.0-master+$Format:%H$
    kubeletVersion: v1.26.10-kubeedge-v0.0.0-master+$Format:%h$
    machineID: 5dbfb12414a3456d9014d88183e338b1
    operatingSystem: linux
    osImage: Ubuntu 22.04.4 LTS
    systemUUID: 5dbfb12414a3456d9014d88183e338b1
```

#### 2、实现 controller 

1、新建一个客户端

```go
func startNodeController(ctx context.Context, cfg *rest.Config, labelSelector, prometheusAddr string, nodeExporterPort int) {
    kubeClient, err := kubernetes.NewForConfig(cfg)
    if err != nil {
        setupLog.Error(err, "Error building kubernetes clientset")
        os.Exit(1)
    }
    // 新增一个远程客户端，通过远程集群的 admin.conf 创建
    remoteClient, err := createRemoteClient("./admin.conf")
    if err != nil {
        klog.Fatalf("Failed to create remote client: %v", err)
    }

    kubeInformerFactory := kubeinformers.NewSharedInformerFactory(kubeClient, time.Second*60)
    nodeController := controller.NewNodeController(kubeClient, remoteClient, kubeInformerFactory.Core().V1().Nodes(), labelSelector, prometheusAddr, nodeExporterPort)

    // notice that there is no need to run Start methods in a separate goroutine. (i.e. go kubeInformerFactory.Start(ctx.done())
    // Start method is non-blocking and runs all registered informers in a dedicated goroutine.
    kubeInformerFactory.Start(ctx.Done())
    nodeController.Start(ctx.Done())
}
```

2、创建远程集群客户端的函数

```go
// 创建远程集群客户端的函数
func createRemoteClient(kubeconfigPath string) (kubernetes.Interface, error) {
    config, err := clientcmd.BuildConfigFromFlags("", kubeconfigPath)
    if err != nil {
        return nil, fmt.Errorf("failed to build config from kubeconfig: %v", err)
    }

    // 打印连接信息
    klog.Infof("Remote cluster host: %s", config.Host)

    // 临时解决方案：跳过证书验证
    config.TLSClientConfig.Insecure = true
    config.TLSClientConfig.CAData = nil
    config.TLSClientConfig.CAFile = ""

    clientset, err := kubernetes.NewForConfig(config)
    if err != nil {
        return nil, fmt.Errorf("failed to create clientset: %v", err)
    }

    // 测试连接
    _, err = clientset.CoreV1().Nodes().List(context.Background(), metav1.ListOptions{})
    if err != nil {
        klog.Errorf("Test connection failed: %v", err)
        // 打印详细错误信息
        klog.Errorf("Error type: %T", err)
        if statusErr, ok := err.(*errors.StatusError); ok {
            klog.Errorf("Status code: %d", statusErr.Status().Code)
            klog.Errorf("Status reason: %s", statusErr.Status().Reason)
            klog.Errorf("Status message: %s", statusErr.Status().Message)
        }
    }

    return clientset, nil
}
```

3、实现同步逻辑

```go
func (nc *NodeController) nodeObjectSyncsAman() {
    // 1.get nodes with machine.type=aman label selector
    selector := labels.SelectorFromSet(labels.Set{"machine.type": "aman"})
    nodeList, err := nc.nodesLister.List(selector)
    if err != nil {
        klog.Errorf("Failed to list aman nodes, error: %s", err.Error())
        return
    }
    if len(nodeList) == 0 {
        return
    }

    // 2.initializes node status map
    nodes := make(map[string]string)
    nodeStatus := make(map[string]corev1.ConditionStatus)
    for _, node := range nodeList {
        nodes[getNodeIp(node)] = node.Name
        nodeStatus[node.Name] = corev1.ConditionFalse
    }

    klog.Infof("Local nodes: %+v", nodes)
    klog.Infof("Local node status: %+v", nodeStatus)

    // 3.get node status from another k8s cluster
    remoteNodes, err := nc.remoteKubeClientset.CoreV1().Nodes().List(context.TODO(), metav1.ListOptions{})
    if err != nil {
        klog.Errorf("Failed to list nodes from remote cluster: %v", err)
        return
    }

    klog.Infof("Remote nodes count: %d", len(remoteNodes.Items))
    for _, node := range remoteNodes.Items {
        klog.Infof("Remote node: %s, IP: %s", node.Name, getNodeIp(&node))
    }

    // 遍历远程集群的节点，更新节点状态
    for _, remoteNode := range remoteNodes.Items {
        remoteNodeIP := getNodeIp(&remoteNode)
        klog.Infof("Processing remote node: %s, IP: %s", remoteNode.Name, remoteNodeIP)
        
        if localNodeName, exists := nodes[remoteNodeIP]; exists {
            klog.Infof("Found matching local node: %s for remote node: %s", localNodeName, remoteNode.Name)
            // 检查远程节点的状态
            for _, condition := range remoteNode.Status.Conditions {
                if condition.Type == corev1.NodeReady {
                    klog.Infof("Remote node %s Ready condition: %v", remoteNode.Name, condition.Status)
                    nodeStatus[localNodeName] = condition.Status
                    break
                }
            }
        } else {
            klog.Warningf("No matching local node found for remote node IP: %s", remoteNodeIP)
        }
    }

    klog.Infof("Local node status after update: %+v", nodeStatus)
    // 6.update node status
    for nodeName, status := range nodeStatus {
        // get node by client-go informer
        node, err := nc.nodesLister.Get(nodeName)
        if err != nil {
            klog.Errorf("Failed to get node(%s), error: %s", nodeName, err.Error())
            continue
        }
        // update node status condition
        for i, condition := range node.Status.Conditions {
            if condition.Type == corev1.NodeReady {
                currentTime := metav1.Now()
                if status == corev1.ConditionTrue {
                    node.Status.Conditions[i].Reason = "EdgeReady"
                    node.Status.Conditions[i].Message = "edge is posting ready status"
                } else {
                    node.Status.Conditions[i].Reason = "NodeStatusUnknown"
                    node.Status.Conditions[i].Message = "Kubelet stopped posting node status."
                }
                node.Status.Conditions[i].Status = status
                node.Status.Conditions[i].LastHeartbeatTime = currentTime
                node.Status.Conditions[i].LastTransitionTime = currentTime
                break
            }
        }
        // update node status by client-go
        _, err = nc.kubeClientset.CoreV1().Nodes().UpdateStatus(context.TODO(), node, metav1.UpdateOptions{})
        if err != nil {
            klog.Errorf("Failed to update node(%s) status, error: %s", nodeName, err.Error())
            continue
        }
    }
}
```

#### 3、内网穿透

通过 frpc 实现
