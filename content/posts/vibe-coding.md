---
title: "Vibe Coding"
date: 2025-06-20T15:35:26+08:00
draft: true
---

## Vide Codeing 工具使用总结

### 2025 大模型花费

| 模型        | 价格（人民币） | 途径                      |
| ----------- | -------------- | ------------------------- |
| Trae VIP    | 21.71          | 官网                      |
| Gemini Pro  | 60             | 咸鱼 购买教育邮箱         |
| Claude Code | 442    | CC代理 |
|             |                |                           |
|             |                |                           |



### Chat

![image-20250620161201149](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20250620161201149.png)

- 通义千问 查询
- Kimi 查询
- DeepSeek 模块 函数
- ChatGPT 图片生成
- Gemini  重度使用，大量代码
- Claude  方案设计

### IDE

![image-20250620161717431](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20250620161717431.png)

#### VScode

配置环境，为其他IDE做配置导入

#### cursor

需要没有额度 很少用

#### windsurf

需要没有额度 很少用

#### Trae

使用 Trae 国际版 

trae 设置从vscode同步配置

![image-20250620162410653](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20250620162410653.png)



#### Antigravity



 截止到2025年12月，最终使用的IDE主要是  Antigravity + vscode。其它的因为不免费+缺少大模型而渐渐不再使用。

Kiro TraeCN Qoder 

### Claude Code

![Claude Code Review: How to be a 10x Coder](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/Claude-Code-Img.jpg)

很贵很强大

### 案例

#### 案例一：星群资源管理与任务管理系统

Gemini + trae 

1、实现了node-controller，对资源的初始化和监控

2、实现了 deployment-controller，job-controller 对任务状态的监控、状态更新、资源的申请与释放。

3、实现了退火调度算法的升级

代码量 10000+

#### 案例二：DDPG分布式星地协同推理任务调度系统

Claude code +  trae

本项目是一个基于DDPG（Deep Deterministic Policy Gradient）强化学习算法的分布式星地协同推理任务调度系统。系统能够智能地在卫星和地面站之间分配计算任务，优化资源利用率，降低通信成本，提升整体系统性能。



#### 案例三：星地通信框架

Claude code

## 实践总结

### 经验1

```yaml
Vide coding 会设定一个任务，通过 ChatGPT Claude Gemini deepseek kimi qwen 等，获取答案，然后汇总。
一个 prompt 对应多个答案
一个对话里面有多个信息
如何把他们汇总集中 形成最后的方案，代码。提交到 git 代码仓库。最后形成闭环。
```



### 经验2

```
Vidcoding 三个阶段
函数
模块
0-1
阶段不同，我们的问题就越来越多。所以从不同AI的对话也越来越多。我们从这些对话中得到答案。
得到函数代码
得到模块代码、然后代码 debug ，如果功能复杂或者模块比较多。可以使用Claude code。
得到多个方案，简易demo代码，对比测试，排除方案，得到最终方案。 然后详细方案设计。模块设计。

但是软件开发是从方案到模块代码再到函数代码。
```

### 经验3 Vide coding 黄金法则

```

方案阶段:
一个对话框里面最好只聚焦一个问题，方便方案的变更。不然对话框不好管理。又不能删除某个对话。
所有AI生成的成果都是成本，而不是资产。需要你将结果融入到自己的目标方案之中。用完就删除。不用担心后面这些好的 idea 还会用到，用你的目标方案重新生成就好。如果不确定哪种方案好，就把其当作备用方案或者对比方案。
md文档和word文档双轮驱动，md是资料的整理，word是思考的结晶
```

