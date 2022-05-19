# Mlops 产品研习录


<!--more-->

4.6号，听了公众号“M小姐研习录”的一个直播，`下一个infra 百亿美金战场在哪里？`。最近刚好也在用kubeflow做一些infra的工作。所以就对直播中提到的一些产品进行梳理和体验。

关注M小姐的公众号是因为她的一篇关于Hashicorp（terraform的母公司，开发了一系列Infra-as-code的工具）总结性文章，写的非常好。[【年度公司】Hashicorp：160亿美金的开源标杆，15000字的研究笔记，2021年不遗憾](https://mp.weixin.qq.com/s/Y2A7-Ui2nzUgodkEbgR6lQ)

## databricks

>  All your data, analytics and AI on one platform

因为没有优秀的开发者社区运营和推广团队，Spark变现比较难，之后团队成员决定成立Databricks，以商业化方式推动Spark社区发展。可以把 databricks 称为 云化的 spark。

除了spark，databricks还有这些产品：开发和维护 AI 生命周期管理平台 MLflow、数据分析工具 Koalas 和 Delta Lake。Delta Lake 为Apache Spark 和其他大数据引擎提供可伸缩的 ACID 事务，让用户可以基于 HDFS 和云存储构建可靠的数据湖（Data Lakes数据湖是一种数据存储理念）。

全球已经有7000 多家组织（包括荷兰银行、康泰纳仕、H&M 集团、再生元和壳牌）依靠 Databricks 实现大规模数据工程、协作数据科学、全生命周期机器学习和业务分析。

### MLflow

> An open source platform for the machine learning lifecycle

和kubeflow类似的产品，可以看看两者的差别 [THe Cheesy Analogy of MLflow and Kubeflow](https://medium.com/weareservian/the-cheesy-analogy-of-mlflow-and-kubeflow-715a45580fbe)

具体使用实践，可以参考这个系列文章 [mlflow 101](https://medium.com/tag/mlflow-101)

[Mlfow 官方文档](https://mlflow.org/docs/latest/quickstart.html)

## argo

### Argo CD

从代码到环境的部署

[argo cd官方文档](https://argo-cd.readthedocs.io/en/stable/)

[GitOps 持续部署工具 Argo CD 初体验](https://mp.weixin.qq.com/s/Hgp7N_HPkpFjfP_qcl4Fzg)



### Argo workflow

[argo workflow官方文档](https://argoproj.github.io/argo-workflows/)

[Argo Workflows-Kubernetes的工作流引擎](https://cloud.tencent.com/developer/article/1810139)



> 1.最新版本的argo-server有问题，回退到V3.2.11 2.修改 workflow-controller-configmap 和 artifact-repositories 的 minio endpoint地址 为cluster IP。



### Seldon

An open source platform to deploy your machine learning models on Kubernetes at massive scale.

[seldon 官方文档](https://docs.seldon.io/projects/seldon-core/en/latest/)



### **Metaflow**

>  A framework for real-life data science



### Prefect



### snorkel

> **AI beyond** **manual labeling**



### Apache Airflow

> Airflow is a platform created by the community to programmatically author, schedule and monitor workflows.



### valohai



> 



### BentoML

>  Simplify Model Deployment



## 平台

cube是tme开源的一站式云原生机器学习平台

[Cube Studio](https://github.com/tencentmusic/cube-studio)

[火山引擎大规模机器学习平台架构设计与应用实践](https://mp.weixin.qq.com/s/--pWXB1FL8Qf_9mIrVMvYA)

