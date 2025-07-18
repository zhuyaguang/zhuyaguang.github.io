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
| Claude Code | 90             | 代理，买了两天+一周体验券 |
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

