---
title: "为什么说 k8s 是新时代的Linux "
date: 2023-12-04T16:19:35+08:00
draft: true
---

我们经常说  Kubernetes 已经取代了 Linux 成为下一代的操作系统了。此话怎讲，看下面这张图片，传统Linux不管是用户态还是内核态，在 k8s 里面都有与其对应的服务。

![20191020205457259](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/20191020205457259.jpeg)

所以在 云原生时代，有很多 以 Kubernetes 为内核构建的分布式操作系统。就像 Linux 时代的 ubuntu，centos 一样。最有名当属 KubeWharf 、sealos、KubeSphere。

### kubesphere

官网：https://kubesphere.io/zh/

KubeSphere 愿景是打造一个以 Kubernetes 为内核的云原生分布式操作系统，它的架构可以非常方便地使第三方应用与云原生生态组件进行即插即用（plug-and-play）的集成，支持云原生应用在多云与多集群的统一分发和运维管理。

### sealos

官网：https://sealos.io/zh-Hans/

以 Kubernetes 为内核 云操作系统: Sealos 。整个数据中心抽象成一台服务器，一切皆应用，像使用个人电脑一样使用 Sealos！

### KubeWharf

官网：https://github.com/kubewharf

KubeWharf 是一套以 Kubernetes 为基础构建的分布式操作系统，由一组云原生组件构成，专注于提高系统的可扩展性、功能性、稳定性、可观测性、安全性等，以支持大规模多租集群、在离线混部、存储和机器学习云原生化等场景。



那么 以 Kubernetes  为内核的分布式操作系统，还需要做哪些事情呢。随着 k8s 集群的快速膨胀，元数据存储，多租户管理，kube-apiserver 负载均衡，多集群调度，可观测性，成本优化。这些都是亟需解决的问题。让我们看看 KubeWharf 是怎么解决的。

## 元数据存储-KubeBrain 

项目地址：https://github.com/kubewharf/kubebrain

大家都看过下面这张图，etcd 已经成为了云原生生态的瓶颈。K8s 中所有组件都与 APIServer 交互，而 APIServer 则需要将集群元数据持久化到 etcd 中。随着单个集群规模的逐渐增大，存储系统的读写吞吐以及总数据量都会不断攀升，etcd 不可避免地会成为整个分布式系统的瓶颈。

![img](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/b87eb23163e2472a9fe9204ccdaa1c34.png)

为了应对云原生浪潮下的大规模集群状态信息存储的可扩展性和性能问题，字节实现并开源了 KubeBrain 这个项目。

> KubeBrain 是字节跳动针对 Kubernetes 元信息存储的使用需求，基于分布式 KV 存储引擎设计并实现的取代 etcd 的元信息存储系统，支撑线上超过 20,000 节点的超大规模 Kubernetes 集群的稳定运行。---From 字节跳动云原生工程师薛英才[《 基于分布式 KV 存储引擎的高性能 K8s 元数据存储项目 KubeBrain》](https://mp.weixin.qq.com/s/lxukeguHP1l0BGKbAa89_Q)

KubeBrain 相比于 etcd 有以下优势：

- **无状态**
- **高性能**
- **扩展性好**
- **高可用** 
- **兼容性**
- **水平扩容**

KubeBrain 采用主从架构，主节点负责处理写操作和事件分发，从节点负责处理读操作，主节点和从节点之间共享一个分布式强一致 KV 存储。避免了 etcd 单点瓶颈、限流能力弱、串行写入、长期运行可用性低等问题。

![图片](https://mmbiz.qpic.cn/mmbiz_png/FMhibf6tm6dAiaKLSM4ESYPKdK0oHL474By2UONCC6NpqQbkiabPjMV3qdbupwvU9XPvkdnbz5kqGZJXnIZ1ezs7Q/640?wx_fmt=png&tp=wxpic&wxfrom=5&wx_lazy=1&wx_co=1)

##  Kube-apiserver 负载均衡-KubeGateway

项目地址：https://github.com/kubewharf/kubegateway

大家都知道 Kube-apiserver 是整个集群的入口，随着集群规模扩大到 上万节点的时候，Kube-apiserver 压力非常大，所有资源的增删改查操作都需要经过 kube-apiserver。所以 Kube-apiserver 的高可用决定了以 Kubernetes  为内核的分布式操作系统的高可用。

> KubeGateway 是字节跳动针对 kube-apiserver 流量特征专门定制的七层网关，它彻底解决了 kube-apiserver 负载不均衡的问题，同时在社区范围内首次实现了对 kube-apiserver 请求的完整治理，包括请求路由、分流、限流、降级等，显著提高了 Kubernetes 集群的可用性。---From  字节跳动云原生工程师章骏[《Kubernetes 集群 kube-apiserver 请求的负载均衡和治理方案 KubeGateway》](https://mp.weixin.qq.com/s/sDxkXPmgtCknwtnwvg2EMw)

KubeGateway 作为七层网关接入和转发 kube-apiserver 的请求,具有以下优势：

- 对于客户端完全透明；
- 支持代理多个 K8s 集群的请求；
- 负载均衡为 HTTP 请求级别；
- 高扩展性的负载均衡策略；
- 支持灵活的路由策略；
- 配置管理云原生化；
- 对 kube-apiserver 请求的完整治理。



下面展示了普通的  kube-apiserver 请求通过 KubeGateway 处理的过程。

* **请求解析**：主要是将 kube-apiserver 的请求分为两种，**资源请求**（如对 Pod 的 CRUD）和 **非资源请求**（如访问 /healthz 和 /metrics）

* **路由匹配**：通过解析出来的多维度路由字段，我们可以利用这些字段做更精细化的流量治理，比如分流，限流，熔断等。

* **用户认证**：KubeGateway 支持证书认证和token认证两种方式。下面是 KubeGateway 中的[源码](https://github.com/kubewharf/kubegateway/blob/main/pkg/gateway/proxy/authenticator/config.go#L108)。

  ```go
  	// x509 client cert auth
  	if c.ClientCert != nil {
  		a := c.ClientCert.New()
  		authenticators = append(authenticators, a)
  	}
  
  	if c.TokenRequest != nil {
  		var tokenAuth authenticator.Token
  		if c.TokenRequest.ClusterClientProvider != nil {
  			tokenAuth = webhook.NewMultiClusterTokenReviewAuthenticator(c.TokenRequest.ClusterClientProvider, c.TokenSuccessCacheTTL, c.TokenFailureCacheTTL, c.APIAudiences)
  		}
  		if tokenAuth != nil {
  			authenticators = append(authenticators, bearertoken.New(tokenAuth), websocket.NewProtocolAuthenticator(tokenAuth))
  			securityDefinitions["BearerToken"] = &spec.SecurityScheme{
  				SecuritySchemeProps: spec.SecuritySchemeProps{
  					Type:        "apiKey",
  					Name:        "authorization",
  					In:          "header",
  					Description: "Bearer Token authentication",
  				},
  			}
  		}
  	}
  
  ```

* **请求治理**:包括**负载均衡**、**健康监测**、**限流**、**降级**。最近滴滴 k8s 集群升级出了问题，其实完全可以通过KubeGateway 限流降级来达到打车服务的可用。

* **请求治反向代理**：包括**Impersonate（用户扮演）**、**HTTP2 多路复用**、**Forward & Exec 类请求处理**。



![图片](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/640-20231206103253489.png)

## 多租户管理-KubeZoo

项目地址：https://github.com/kubewharf/kubezoo

Linux 操作系统有很多用户，root 用户，普通用户等等，作为以 Kubernetes 为基础构建的分布式操作系统，我们默认可以通过 **Namespace**来对资源进行隔离。但是 Namespace 也有很多不足，租户只能访问  namespace 级别的资源，比如deployment、pod 和 pvc 。集群级别的资源，比如 PV、clusterrole 则无法访问。API访问权限低。

> KubeZoo 是由字节跳动自研的 Kubernetes 轻量级多租户项目，它基于协议转换的核心理念，在一个物理的 Kubernetes Master 上虚拟多个租户，具备轻量级、兼容原生 API 、无侵入等特点，是一种打造 Serverless Kubernetes 底座的优良方案。---From [《KubeZoo：字节跳动轻量级多租户开源解决方案》](https://mp.weixin.qq.com/s/SUNuvFz4HBmFk-XDN0mINg)



那么 KubeZoo 是怎么解决这个问题的呢，思路还挺简单的，就是通过在资源的 name/namespace 等字段上增加租户的唯一标识。

以下图为例，租户 tenant2 有 default 和 prod 两个 namespace，其在上游的真实 namespace 则是加上了租户的前缀，故为 tenant2-default 和 tenant2-prod。所以 tenant1和 tenant2 都有 default 的 namespace ，但其实是两个不同的namespace。



![img](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/design-ideas.png)

由于 tenant 的 name 字段存储在 etcd 中全局唯一。长度固定 6 位字符串(包括字符或者数字)，理论上避免了不同 namespace 的资源命名冲突问题。

```yaml
apiVersion: tenant.kubezoo.io/v1alpha1
kind: Tenant
metadata:
name: "foofoo"
annotations:
  ...... # add schema for tenant(optional)
spec:
  id: 0
```

以上就是 KubeWharf 2022年首批三个项目开源：

- **KubeBrain**：高性能元信息存储系统
- **KubeZoo**：轻量级的 Kubernetes 多租户项目
- **KubeGateway**：专为 kube-apiserver 设计并定制的七层负载均衡代理

## 可观测性-Kelemetry

项目地址：https://github.com/kubewharf/kelemetry

2023年应该是可观测性元年，OpenTelemetry 的出现，让大家对可观测性有了更多的选择。它结合了 OpenTracing 与 OpenCensus 两个项目，成为了一个厂商无关、平台无关的支撑可观测性三大支柱的标准协议和开源实现。加上 eBPF 这个黑魔法，解决了可观测性**零侵扰解决落地难的问题**。其中沙箱机制是 eBPF 有别于 APM 插桩机制的核心所在，**「沙箱」在 eBPF 代码和应用程序的代码之间划上了一道清晰的界限，使得我们能在不对应用程序做任何修改的前提下，通过获取外部数据就能确定其内部状态**。

针对 Kubernetes 控制面的可观测性，Kelemetry 通过收集并连接来自不同组件的信号，并以追踪的形式展示相关数据。来解决 Kubernetes 可观察性数据孤岛的问题。

> Kelemetry 是字节跳动开发的用于 Kubernetes 控制平面的追踪系统，它从全局视角串联起多个 Kubernetes 组件的行为，追踪单个 Kubernetes 对象的完整生命周期以及不同对象之间的相互影响。--- From [《面向 Kubernetes 控制面的全局追踪系统》](https://mp.weixin.qq.com/s/U-P9tZhX4rT5wTaSnqfoZg)

Kelemetry 主要有以下特性：

* 将对象作为跨度

* 审计日志收集
* Event 收集
* 将对象状态与审计日志关联
* 前端追踪转换
* 突破时长限制
* 多集群支持

有了 Kelemetry，大大降低了  Kubernetes 定位问题的复杂性。

## 多集群调度-KubeAdmiral

项目地址：https://github.com/kubewharf/kubeadmiral

随着业务的增长，很多公司都使用了公有云和私有云。其中公有云又使用了多家的产品。因为没有一家的云是 100% 可靠的，最近阿里云事故频发，采用多云、混合云架构已经是业界共识了。

> 随着多云、混合云愈发成为业内主流形态，Kubernetes 成为了云原生的操作系统，实现了对基础设施的进一步抽象和规范，为应用提供更加统一的标准接口。在此基础上，我们**引入 Kubernetes 集群联邦**作为分布式云场景下的云原生系统底座，面向应用提供统一的平台入口，提升应用跨集群分发的能力，做好应用跨集群的分发调度，管理好多个云云原生场景下的基础设施。---From [《基于 Kubernetes 的新一代多集群编排调度引擎》](https://mp.weixin.qq.com/s/aS18urPF8UB4K2I_9ECbHg)

**KubeAdmiral** 是基于 KubeFed v2 基础上研发，并支持  Kubernetes 原生 API 的多集群联邦解决方案。

KubeAdmiral  具有以下优势：

* **丰富的多集群调度能力**
* **调度能力可拓展**
* **应用调度失败自动迁移***
* **根据集群水位动态调度资源***
* **副本分配算法改进**
* **支持原生资源**

KubeAdmiral 在字节内部管理超过 21 万台机器、1000 万+ pod，经历了重重考验。



![图片](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/640-20231206154908473.png)

## 成本优化-Katalyst

项目地址：https://github.com/kubewharf/katalyst-core

降本增笑这个词最近很火，但是怎么提高 Kubernetes 集群的资源利用率，一直是大家最关心的问题。

> 通过对离线作业进行云原生化改造，我们使它们可以在同一个基础设施上进行调度和资源管理。该体系中，最上面是统一的资源联邦实现多集群资源管理，单集群中有中心的统一调度器和单机的统一资源管理器，它们协同工作，实现在离线一体化资源管理能力。--From [《Katalyst：字节跳动云原生成本优化实践》](https://mp.weixin.qq.com/s/d4R2mIzkd-7FIcNKK5S6LQ)

Katalyst  解决了云原生场景下的资源不合理利用的问题，有以下优势：

- QoS-Based 资源模型抽象
- 资源弹性管理
- 微拓扑及异构设备的调度、摆放
- 精细化资源分配、隔离

Katalyst 架构主要分为下面四层：

-  API层
- 中心层
- 单机层
- 内核层

![图片](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/640-20231206160257526.png)



以上就是 2023年 KubeWharf 开源的三个项目

- **Kelemetry**：面向 Kubernetes 控制面的全局追踪系统
- **KubeAdmiral**：多云多集群调度管理项目
- **Katalyst**：在离线混部、资源管理与成本优化项目

## 总结

软件吞噬世界，云原生吞噬软件。构建以 Kubernetes 为基础构建的分布式操作系统，KubeWharf 在各个维度提供了优秀的解决方案。字节发布了分布式云原生平台（Distributed Cloud Native Platform，DCP）是对 上述 KubeWharf 组件的深度整合。降低了多云管理的门槛。同时，感谢字节开放共享的开源精神，这 6 个项目相互之间**不存在绑定依赖**，都是独立项目，所以大家可以自己任意搭配，打造自己的云原生操作系统。
