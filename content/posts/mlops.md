---
title: "Mlops 产品研习录"
date: 2022-05-09T10:13:22+08:00
draft: true
description: "MLops 产品大汇总"
---

<!--more-->

4.6号，听了公众号“M小姐研习录”的一个直播，`下一个infra 百亿美金战场在哪里？`。最近刚好也在用 kubeflow 做一些 infra 的工作。所以就对直播中提到的一些产品进行梳理和体验。

关注M小姐的公众号是因为她的一篇关于Hashicorp（terraform的母公司，开发了一系列 Infra-as-code 的工具）总结性文章，写的非常好。[【年度公司】Hashicorp：160亿美金的开源标杆，15000字的研究笔记，2021年不遗憾](https://mp.weixin.qq.com/s/Y2A7-Ui2nzUgodkEbgR6lQ)

## [databricks](https://databricks.com/)

>  All your data, analytics and AI on one platform

因为没有优秀的开发者社区运营和推广团队，Spark变现比较难，之后团队成员决定成立 Databricks，以商业化方式推动 Spark 社区发展。可以把 databricks 称为 云化的 spark。

除了spark，databricks还有这些产品：开发和维护 AI 生命周期管理平台 MLflow、数据分析工具 Koalas 和 Delta Lake。Delta Lake 为Apache Spark 和其他大数据引擎提供可伸缩的 ACID 事务，让用户可以基于 HDFS 和云存储构建可靠的数据湖（Data Lakes数据湖是一种数据存储理念）。

全球已经有7000 多家组织（包括荷兰银行、康泰纳仕、H&M 集团、再生元和壳牌）依靠 Databricks 实现大规模数据工程、协作数据科学、全生命周期机器学习和业务分析。

### MLflow

> An open source platform for the machine learning lifecycle

和 kubeflow 类似的产品，可以看看两者的差别 [THe Cheesy Analogy of MLflow and Kubeflow](https://medium.com/weareservian/the-cheesy-analogy-of-mlflow-and-kubeflow-715a45580fbe)

具体使用实践，可以参考这个系列文章 [mlflow 101](https://medium.com/tag/mlflow-101)

[Mlfow 官方文档](https://mlflow.org/docs/latest/quickstart.html)

## argo+volcano+(seldon/BentoML)搭建云原生机器学习平台

### Argo CD

从代码到环境的部署

[argo cd官方文档](https://argo-cd.readthedocs.io/en/stable/)

[GitOps 持续部署工具 Argo CD 初体验](https://mp.weixin.qq.com/s/Hgp7N_HPkpFjfP_qcl4Fzg)



### Argo workflow

[argo workflow官方文档](https://argoproj.github.io/argo-workflows/)

[Argo Workflows-Kubernetes的工作流引擎](https://cloud.tencent.com/developer/article/1810139)



> 1.最新版本的argo-server有问题，回退到V3.2.11 
>
> 2.修改 workflow-controller-configmap 和 artifact-repositories 的 minio endpoint地址 为cluster IP。
>
> kubectl -n argo port-forward --address 0.0.0.0 svc/argo-server 2746:2746

### volcano

[volcano文档](https://volcano.sh/zh/)

### Seldon

An open source platform to deploy your machine learning models on Kubernetes at massive scale.

[seldon 官方文档](https://docs.seldon.io/projects/seldon-core/en/latest/)

安装 seldom

* 安装helm
* [安装istio](https://istio.io/latest/docs/setup/install/helm/)



> seldon 对 pytorch 支持不太友好呢

### BentoML

>  Simplify Model Deployment

[BentoML 官网](https://docs.bentoml.org/en/latest/quickstart.html)



## 其它产品

### **Metaflow**

>  A framework for real-life data science

[Metaflow官网](https://docs.metaflow.org/)



### Prefect



### snorkel

> **AI beyond** **manual labeling**



### Apache Airflow

> Airflow is a platform created by the community to programmatically author, schedule and monitor workflows.



### valohai







## 平台

1.[Cube Studio](https://github.com/tencentmusic/cube-studio)

cube是tme开源的一站式云原生机器学习平台



2.[火山引擎大规模机器学习平台架构设计与应用实践](https://mp.weixin.qq.com/s/--pWXB1FL8Qf_9mIrVMvYA)



3.[鹏城实验室启智章鱼平台](https://octopus.openi.org.cn/docs/introduction/intro/)

Octopus是一款面向多计算场景的一站式融合计算平台。平台主要针对AI、HPC等场景的计算与资源管理的需求来设计，向算力使用用户提供了对数据、算法、镜像、模型与算力等资源的管理与使用功能，方便用户一站式构建计算环境，实现计算。同时，向集群管理人员提供了集群资源管理与监控，计算任务管理与监控等功能，方便集群管理人员对整体系统进行操作与分析。

Octopus平台底层基于容器编排平台Kubernetes ，充分利用容器敏捷、轻量、隔离等特点来实现计算场景多样性的需求。



4.[百度AI原生云实践: 基于容器云打造 AI 开发基础设施](https://mp.weixin.qq.com/s/UckkV8kFfPE6JZjui_bbtA)



5.[趋动科技GPU池化技术](https://mp.weixin.qq.com/s/y38qjIBn4w0_HPH_3pqhcw)

GPU与CPU的解耦是智算中心建设的目标之一。GPU虚拟化以及GPU资源池建设的意义在于解耦AI应用与GPU服务的深度绑定，把 GPU 的静态分配变成动态分配，GPU 使用率获得4倍以上提升。借助OrionX的池化能力，AI应用无需关注部署的节点有没有GPU资源，只要在智算中心网络可达，均可以通过OrionX远程调用的功能，在整个智算中心范围内调用符合要求的GPU资源进行AI计算。



## 资料

[MLOps London](https://www.youtube.com/channel/UCSBfllj_pRPB36TAZJfjXWg)
