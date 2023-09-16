---
title: "DeepFlow 可观测性 Meetup"
date: 2023-09-15T17:25:47+08:00
draft: true
---

![image-20230915174106980](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20230915174106980-20230915174122410.png)



kubesphere 杭州用户委员会 

广州 deepflow 合办 meetup 欢迎大家投稿参与



最近开始学 可观测性 现在将学习的结果与大家一起分享。

## 介绍 kubesphere 以及其云原生可观测性

KubeSphere 愿景是打造一个以 Kubernetes 为内核的云原生分布式操作系统，它的架构可以非常方便地使第三方应用与云原生生态组件进行即插即用（plug-and-play）的集成，支持云原生应用在多云与多集群的统一分发和运维管理。

下面是 kubesphere 的主要的观测指标，包括集群的整体概况，集群的主要组件 API- server scheduler 以及一些主要的硬件指标。

这种可观测性太宏观了，适合给领导演示，但作为开发，希望可观测性能够给自己的业务带来方便，可以更快定位问题

于是我们在业务代码中进行埋点，发出追踪、指标 、日志。但这又带来一系列问题，比如 没有标准化的数据格式，缺乏数据可移植性和用户维护代码的高成本。

因此我们需要  OTel 来统一标准化。

![1](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/1.png)

## 介绍 Otel 的核心概念

可观测性主要分三大块，日志、指标、和链路追踪。日志和指标基本上是成埃落定。（CNCF全景图）

**那 Otel 有哪些核心的概念呢**

Tracer Provider 构建 tracer ，tracer  包含众多 span。

span 由 Trace Context 相互关联组装在一起，由不同语言的进程、虚拟机、数据中心。

最核心的就是 collector ，是一个与厂商无关的实现方式，用于接受、处理、导出 遥测数据。

receiver：将数据发送到收集器中。

processor：处理数据

exporter：导出数据

![2](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/2.png)

![3](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/3.png)

## ![4](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/4.png)





## 微服务介绍

一个各种语言组成的购书微服务，包括目录服务，库存服务、支付服务、用户服务

Otel 官网 和 deepflow 官网都有很复杂的demo 调用关系很复杂



 每个微服务环境配置都不一样，所以最好是容器化部署。

部署 collector 容器，进行配置

部署 jaeger 容器，导出数据。



目前是两层功力 



## 集成 OTel



埋点之前第一件事就是安装 OTel SDK ，导入依赖。

埋点分两大块，一部分是 初始化 全局 Tracer。

构建一个 Provider，里面包含了 resource 指定了服务名称。

构建一个 exporter 制定数据导出到哪里

构建一个 processor 

另外一块就是 代码埋点



java python 支持自动埋点

sping boot flask

Node Golang  手动埋点

Gin 

![6](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/6.png)



![7](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/7.png)

![9](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/9.png)

## deep flow 解决方案



能不能不埋点呢 ，当然可以 

Deepflow 利用 eBPF zero code 做到

DeepFlow [[GitHub](https://github.com/deepflowio/deepflow)] 旨在为复杂的云原生应用提供简单可落地的深度可观测性。DeepFlow 基于 eBPF 和 Wasm 技术实现了零侵扰（Zero Code）、全栈（Full Stack）的指标、追踪、调用日志、函数剖析数据采集，并通过智能标签技术实现了所有数据的全关联（Universal Tagging）和高效存取。使用 DeepFlow，可以让云原生应用自动具有深度可观测性，从而消除开发者不断插桩的沉重负担，并为 DevOps/SRE 团队提供从代码到基础设施的监控及诊断能力。

在 kubesphere 部署就更简单了

我理解最终的可观测性，是手动+自动双结合，服务自己的业务需求。













