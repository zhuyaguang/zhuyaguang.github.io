---
title: "开发一个自定义调度插件"
date: 2024-06-12T13:44:46+08:00
draft: true
---

## fork Scheduler Plugins

### 开发调度逻辑

github 下载完代码，新建一个你自己的调度插件文件目录，spacecloud.go 里面写上你的调度节点逻辑

![image-20240612135414918](C:\Users\DELL\AppData\Roaming\Typora\typora-user-images\image-20240612135414918.png)



```go
package spacecloud

import (
	"context"
	"fmt"
	v1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/klog/v2"
	"k8s.io/kubernetes/pkg/scheduler/framework"
)

const (
	Name     = "SpaceCloud"
	stateKey = Name + "StateKey"
)

type SpaceCloud struct {
}

var (
	_ framework.PreFilterPlugin = &SpaceCloud{}
	_ framework.FilterPlugin    = &SpaceCloud{}
)

// Name returns name of the plugin.
func (pl *SpaceCloud) Name() string {
	return Name
}

type CloudState struct {
	spaceWorkload bool
	node          string
	satellite     string
}

// 查看 pod 类型 ,是否是 spaceWorkload
func (pl *SpaceCloud) PreFilter(ctx context.Context, state *framework.CycleState, pod *v1.Pod) (*framework.PreFilterResult, *framework.Status) {
	c := CloudState{
		spaceWorkload: false,
		node:          "",
		satellite:     "",
	}
	if pod.Annotations["type"] == "space" {
		c.spaceWorkload = true
	}
	klog.Info("=======pod.Annotations", pod.Annotations["type"])
	klog.Info("=======spaceWorkload", c.spaceWorkload)
	state.Write(stateKey, &c)

	return nil, framework.NewStatus(framework.Success, "Check pod Annotations type , return")
}

func (pl *SpaceCloud) Filter(ctx context.Context, state *framework.CycleState, pod *v1.Pod, nodeInfo *framework.NodeInfo) *framework.Status {
	s, err := state.Read(stateKey)
	if err != nil {
		klog.Infof("Filter: pod %s/%s: read preFilter scheduling context failed: %v", pod.Namespace, pod.Name, err)
		return framework.NewStatus(framework.Error, fmt.Sprintf("read preFilter state fail: %v", err))
	}
	r, ok := s.(*CloudState)
	if !ok {
		return framework.NewStatus(framework.Error, fmt.Sprintf("convert %+v to stickyState fail", s))
	}
	klog.Info("=====", r.spaceWorkload)

	if nodeInfo.Node().Labels["kubernetes.io/role"] == "edge" {
		klog.Infof("====", nodeInfo.Node().Labels["kubernetes.io/role"])
	}

	return nil
}

func (c *CloudState) Clone() framework.StateData {
	return c
}

func New(_ runtime.Object, _ framework.Handle) (framework.Plugin, error) {
	return &SpaceCloud{}, nil
}

// PreFilterExtensions returns prefilter extensions, pod add and remove.
func (pl *SpaceCloud) PreFilterExtensions() framework.PreFilterExtensions {
	return pl
}

// AddPod from pre-computed data in cycleState.
// no current need for this method.
func (pl *SpaceCloud) AddPod(ctx context.Context, cycleState *framework.CycleState, podToSchedule *v1.Pod, podToAdd *framework.PodInfo, nodeInfo *framework.NodeInfo) *framework.Status {
	return framework.NewStatus(framework.Success, "")
}

// RemovePod from pre-computed data in cycleState.
// no current need for this method.
func (pl *SpaceCloud) RemovePod(ctx context.Context, cycleState *framework.CycleState, podToSchedule *v1.Pod, podToRemove *framework.PodInfo, nodeInfo *framework.NodeInfo) *framework.Status {
	return framework.NewStatus(framework.Success, "")
}

```

### 注册你的插件

![image-20240612135629518](C:\Users\DELL\AppData\Roaming\Typora\typora-user-images\image-20240612135629518.png)



### 编译

```
go build -ldflags '-s -w' -o bin/kube-scheduler ./main.go
```



### 配置文件

```yaml
apiVersion: kubescheduler.config.k8s.io/v1
kind: KubeSchedulerConfiguration
clientConnection:
  kubeconfig: "/etc/kubernetes/scheduler.kubeconfig"
profiles:
  - schedulerName: spacecloud
    plugins:
      preFilter:
        enabled:
          - name: SpaceCloud
        disabled:
          - name: "*"
      filter:
        enabled:
          - name: SpaceCloud
        disabled:
          - name: "*"
      reserve:
        disabled:
          - name: "*"
      preBind:
        disabled:
          - name: "*"
      postBind:
        disabled:
          - name: "*"
```



### 启动

注意启动自定义插件需要将原始的调度器插件（root@master1:/etc/kubernetes/manifests/kube-scheduler.yaml）移除。

```
./bin/kube-scheduler --leader-elect=false --config ksc.yaml
```

目前为了调试方便，用二进制启动。最终生产环境应该是以 pod 启动，具体配置 clusterrole 参考[链接](https://kubernetes.io/zh-cn/docs/tasks/extend-kubernetes/configure-multiple-schedulers/)





## 参考链接

[kubernetes组件开发-自定义调度器](https://isekiro.com/kubernetes%E7%BB%84%E4%BB%B6%E5%BC%80%E5%8F%91-%E8%87%AA%E5%AE%9A%E4%B9%89%E8%B0%83%E5%BA%A6%E5%99%A8%E4%B8%89/)

[K8s 调度框架设计与 scheduler plugins 开发部署示例（2024）](https://arthurchiao.art/blog/k8s-scheduling-plugins-zh/)

[Scheduler Plugins 官网](https://scheduler-plugins.sigs.k8s.io/docs/plugins/noderesources/)

[scheduler-plugins GitHub 地址](https://github.com/kubernetes-sigs/scheduler-plugins)
