---
title: "gitlab runner 与 Jenkins 的使用"
date: 2024-07-17T16:52:57+08:00
draft: true
description: "gitlab runner 与 Jenkins 的使用"
---

# gitlab runner 与 Jenkins 的使用

## 部署runner

```
sudo curl -L --output /usr/local/bin/gitlab-runner https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-amd64

sudo chmod +x /usr/local/bin/gitlab-runner

sudo useradd --comment 'GitLab Runner' --create-home gitlab-runner --shell /bin/bash

sudo gitlab-runner install --user=gitlab-runner --working-directory=/home/gitlab-runner
sudo gitlab-runner start


```

[参考链接](https://docs.gitlab.cn/runner/install/linux-manually.html)



## 使用 runner

### 注册
* 在项目中注册

  ![img_6.png](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/img_6.png)

* 在群组中注册

![img_7.png](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/img_7.png)



### shell 类型生成证书

* variables 是环境变量参数
* tags 是指定runner
* script 是执行的脚本
* only 是执行的条件
* artifacts 是生成的证书

```yaml
stages:
  - build

variables:
  HOST: "true"  # 定义一个变量，用于存储主机地址
  host: "0.0.0.0"



build-cert:
  tags:
    - cert
  stage: build
  script:
    - echo "Gen certs..."
    - sh deploy/https/generate_certs.sh $host  # 使用变量替换之前的硬编码地址
    - echo $HOST
    - echo $host
  only:
    variables:
    - $HOST == "true"
  artifacts:
    paths:
      - tj.registry.com/

```

### shell 类型编镜像

```yaml
stages:
  - build

before_script:
  - docker info

build-job:
  stage: build
  image: docker:cli
  tags:
    - shell
  script:
    - pwd
    - echo "Compiling the code..."
    - echo "Compile complete."
    - docker build -t gpu-expotter:v1 .
    - docker tag gpu-expotter:v1 tj.inner1.harbor.com/gitlab-ci/gpu-expotter:v1 # 替换 CI_REGISTRY_IMAGE 为你的镜像仓库地址
    - docker login -u admin -p zjlab12345 tj.inner1.harbor.com # 使用 CI/CD 变量进行认证
    - docker push tj.inner1.harbor.com/gitlab-ci/gpu-expotter:v1 # 推送镜像到 GitLab 的容器注册表或其他镜像仓库

```

### docker 编译二进制

* artifacts 是编译好的二进制

```yaml
stages:
  - build

build-bin:
  tags:
    - bin
  stage: build
  script:
    - echo "Compiling the code..."
    - pwd
    - go build -o ./bin/image-operator cmd/image-operator/main.go  # 使用变量替换之前的硬编码地址
  artifacts:
    paths:
      - bin/
```



### 使用gitlab 私有仓库 go mod 

* 修改配置文件  vim /etc/gitlab/gitlab.rb 

![img_8.png](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/img_8.png)

gitlab-ctl reconfigure
gitlab-ctl restart

* 配置 gitlab 机器和本地机器的hosts

10.11.140.85 gitlab.private.com

### 使用docker 交叉编译

* 安装 buildx

```
sudo apt install docker-buildx
```

* 安装

```
docker run --privileged --rm tonistiigi/binfmt --install all
```

* 编镜像

```
docker buildx build    --platform linux/arm64 -t helloword:v3  .
```

* 构建样例

```yaml
stages:
  - build

before_script:
  - docker info

build-job:
  stage: build
  image: docker:cli
  tags:
    - shell
  script:
    - pwd
    - docker buildx build   --platform linux/arm64 -t helloword:v3  .
    - docker tag helloword:v3 tj.inner1.harbor.com/gitlab-ci/helloword:v3 
    - docker login -u admin -p **** tj.inner1.harbor.com 
    - docker push tj.inner1.harbor.com/gitlab-ci/helloword:v3 
```



## Jenkins 编镜像和二进制

* 启动服务
```shell
docker run -d -u 0 -p 8080:8080 -p 50000:50000 -v /home/jenkins/:/var/jenkins_home -v /var/run/docker.sock:/var/run/docker.sock  -v /usr/bin/docker:/usr/bin/docker  -v  /root/go:/root/go --privileged  jenkins/jenkins
```
通过挂载二进制方式，让docker 的Jenkins 可以使用 docker 和 golang
