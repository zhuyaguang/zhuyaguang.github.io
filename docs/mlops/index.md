# Mlops 产品研习录


<!--more-->

4.6号，听了公众号“M小姐研习录”的一个直播，`下一个infra 百亿美金战场在哪里？`。最近刚好也在用 kubeflow 做一些 infra 的工作。所以就对直播中提到的一些产品进行梳理和体验。

关注M小姐的公众号是因为她的一篇关于Hashicorp（terraform的母公司，开发了一系列 Infra-as-code 的工具）总结性文章，写的非常好。[【年度公司】Hashicorp：160亿美金的开源标杆，15000字的研究笔记，2021年不遗憾](https://mp.weixin.qq.com/s/Y2A7-Ui2nzUgodkEbgR6lQ)

## 一、名词解释



MLOps：Machine learning + DevOps + Data Engineering = MLOps

![image-20220811091106723](/Users/zhuyaguang/Library/Application Support/typora-user-images/image-20220811091106723.png)

CD4ML：机器学习的持续交付

CT：Continuous Training

## 二、[databricks](https://databricks.com/)

>  All your data, analytics and AI on one platform

因为没有优秀的开发者社区运营和推广团队，Spark变现比较难，之后团队成员决定成立 Databricks，以商业化方式推动 Spark 社区发展。可以把 databricks 称为 云化的 spark。

除了spark，databricks还有这些产品：开发和维护 AI 生命周期管理平台 MLflow、数据分析工具 Koalas 和 Delta Lake。Delta Lake 为Apache Spark 和其他大数据引擎提供可伸缩的 ACID 事务，让用户可以基于 HDFS 和云存储构建可靠的数据湖（Data Lakes数据湖是一种数据存储理念）。

全球已经有7000 多家组织（包括荷兰银行、康泰纳仕、H&M 集团、再生元和壳牌）依靠 Databricks 实现大规模数据工程、协作数据科学、全生命周期机器学习和业务分析。

### MLflow

> An open source platform for the machine learning lifecycle

和 kubeflow 类似的产品，可以看看两者的差别 [THe Cheesy Analogy of MLflow and Kubeflow](https://medium.com/weareservian/the-cheesy-analogy-of-mlflow-and-kubeflow-715a45580fbe)

具体使用实践，可以参考这个系列文章 [mlflow 101](https://medium.com/tag/mlflow-101)

[Mlfow 官方文档](https://mlflow.org/docs/latest/quickstart.html)

## 三、argo+volcano+(seldon/BentoML)搭建云原生机器学习平台

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

* 安装 helm
* [安装istio](https://istio.io/latest/docs/setup/install/helm/)



> seldon 对 pytorch 支持不太友好呢

### BentoML

>  Simplify Model Deployment

[BentoML 官网](https://docs.bentoml.org/en/latest/quickstart.html)



## 四、其它产品

### **Metaflow**

>  A framework for real-life data science

[Metaflow官网](https://docs.metaflow.org/)



### Prefect



### snorkel

> **AI beyond** **manual labeling**



### Apache Airflow

> Airflow is a platform created by the community to programmatically author, schedule and monitor workflows.



### valohai

## 五、付费产品

### AIFLOW

 https://www.aiflow.ltd/

### Neptune

https://neptune.ai/



## 六、平台

1.[Cube Studio](https://github.com/tencentmusic/cube-studio)

cube是tme开源的一站式云原生机器学习平台



2.[火山引擎大规模机器学习平台架构设计与应用实践](https://mp.weixin.qq.com/s/--pWXB1FL8Qf_9mIrVMvYA)



3.[鹏城实验室启智章鱼平台](https://octopus.openi.org.cn/docs/introduction/intro/)

Octopus是一款面向多计算场景的一站式融合计算平台。平台主要针对AI、HPC等场景的计算与资源管理的需求来设计，向算力使用用户提供了对数据、算法、镜像、模型与算力等资源的管理与使用功能，方便用户一站式构建计算环境，实现计算。同时，向集群管理人员提供了集群资源管理与监控，计算任务管理与监控等功能，方便集群管理人员对整体系统进行操作与分析。

Octopus平台底层基于容器编排平台Kubernetes ，充分利用容器敏捷、轻量、隔离等特点来实现计算场景多样性的需求。



4.[百度AI原生云实践: 基于容器云打造 AI 开发基础设施](https://mp.weixin.qq.com/s/UckkV8kFfPE6JZjui_bbtA)



5.[趋动科技GPU池化技术](https://mp.weixin.qq.com/s/y38qjIBn4w0_HPH_3pqhcw)

GPU与CPU的解耦是智算中心建设的目标之一。GPU虚拟化以及GPU资源池建设的意义在于解耦AI应用与GPU服务的深度绑定，把 GPU 的静态分配变成动态分配，GPU 使用率获得4倍以上提升。借助OrionX的池化能力，AI应用无需关注部署的节点有没有GPU资源，只要在智算中心网络可达，均可以通过OrionX远程调用的功能，在整个智算中心范围内调用符合要求的GPU资源进行AI计算。



6.[九章云极 DataCanvas](https://datacanvas.io/)

数据智能基础软件供应商。目前九章云极 DataCanvas 主要在算法平台和实时数据上发力。

[AI落地的新范式，就“藏”在下一场软件基础设施的重大升级里](https://mp.weixin.qq.com/s/3MsW03DEz-Wh-Fv3wJWMpA)



7.灵雀云

灵雀云企业级 MLOPS 解决方案中，依托于灵雀云 ACP 以及多项企业级容器平台产品之上，集成 Kubefow, SQLFlow 等组件将提供开箱即用，工业生产级别的 MLOPS 平台。我们希望能逐步开放以上能力，包括 4-Flow （Kubeflow, SQLFlow, MLFlow, ParaFlow），推动MLOPS 技术落地进程。

https://mp.weixin.qq.com/s/rFmrtfZ9nOhHm1mFUL6bcw



## 七、资料

### 文章

[AI工程与实践](https://www.zhihu.com/column/c_1488835248573706240)

MindSpore架构师 王磊的文章

### 演讲分享

[MLOps London](https://www.youtube.com/channel/UCSBfllj_pRPB36TAZJfjXWg)

[数算工程一体化机器学习平台助力 AI 算法敏捷开发](https://qcon.infoq.cn/2022/guangzhou/presentation/4811)

[华为 AI 工程化探索与实践之一站式 MLOps 平台](https://qcon.infoq.cn/2022/guangzhou/presentation/4835)

[机器学习工程化，企业 AI 的下一个起点](https://mp.weixin.qq.com/s/2QEjAx3adB_PItJcn35qag)

[Flink在AI流程中的应用](https://mp.weixin.qq.com/s/VkVd0AOQwfAUiMYFmO63og)

### 公众号

* **[MLOps工程实践](https://mp.weixin.qq.com/s/Bh-_9N4JY3MvbJ5Iw6bWwQ)**

### 课程

https://fullstackdeeplearning.com/course/2022/

### 社区

https://neptune.ai/blog

https://valohai.com/mlops/

https://about.mlreef.com/blog/

https://ml-ops.org/

