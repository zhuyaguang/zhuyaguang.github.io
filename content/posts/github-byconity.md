---
title: "利用 GitHub pages 构建类似 byconity 的网站"
date: 2024-11-26T18:14:01+08:00
draft: true
---

## 利用 GitHub pages 构建类似 byconity 的网站

### 新建一个GitHub 账号

比如： zhuyaguang782126

### 新建一个仓库

> 注意仓库名必须以**用户名**+github.io 

比如： zhuyaguang782126.github.io

![123](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image.png)

### 下载 byconity 源码

1、更新 pnpm 到最新版本

npm install -g pnpm@latest 

2、下载 byconity 源码

 git clone https://github.com/ByConity/byconity.github.io.git

3、进入 byconity 源码目录

cd byconity.github.io

4、安装依赖

pnpm install

5、启动项目

pnpm start

6、访问 http://localhost:3000

能够访问说明本地环境配置OK了


### 拷贝代码到 zhuyaguang782126.github.io

cp -rf byconity.github.io/* zhuyaguang782126.github.io

* 推送代码到 GitHub main 分支


git add . && git commit -m "update" && git push -u origin main


* 新建 gh-pages 分支

git checkout -b gh-pages

* 推送代码到 GitHub gh-pages 分支

git add . && git commit -m "update" && git push -u origin gh-pages

### 部署到 GitHub pages

#### 设置环境变量

代码推送到 GitHub 上之后，会自动触发 GitHub action，然后会发现跑失败了，看下日志 应该是获取不到 secrets.GITHUB_TOKEN 这个值。

我们修改下  代码仓库   `.github/workflows/deploy.yml  ` ` 路径下到 值，把 secrets.GITHUB_TOKEN 改成  secrets.ASS  

![image-20241127075631046](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20241127075631046.png)



#### secrets.ASS 

1、secrets.ASS  是新的变量 如何设置呢

![image-20241127080414360](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20241127080414360.png)



2、点击 New repository secret 

![image-20241127080747811](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20241127080747811.png)



3、那token 怎么获取呢

3.1、第一步打开 GitHub 账号个人设置

![image-20241127081259361](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20241127081259361.png)

3.2、打开开发者设置

![image-20241127081342126](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20241127081342126.png)





3.3、打开 tokens

*![image-20241127081420503](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20241127081420503.png)**

3.4、配置 token

下面框都选上

![image-20241127081521224](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20241127081521224.png)

最后点生成

#### 修改完 部署到 GitHub pages

git add . && git commit -m "update" && git push -u origin main
