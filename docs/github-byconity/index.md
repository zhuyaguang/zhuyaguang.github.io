# 利用 GitHub pages 构建类似 byconity 的网站


## 利用 GitHub pages 构建类似 byconity 的网站

### 新建一个GitHub 账号

比如： zhuyaguang782126

### 新建一个仓库

比如： zhuyaguang782126.github.io

![123](image.png)

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


### 拷贝代码到 zhuyaguang782126.github.io

cp -rf byconity.github.io/* zhuyaguang782126.github.io

* 推送代码到 GitHub main 分支


git add . && git commit -m "update" && git push -u origin main


* 新建 gh-pages 分支

git checkout -b gh-pages

* 推送代码到 GitHub gh-pages 分支

git add . && git commit -m "update" && git push -u origin gh-pages

### 部署到 GitHub pages


#### .github/workflows/deploy.yml  设置 github_token: ${{ secrets.GITHUB_TOKEN }} 

在 GitHub Actions 中，GITHUB_TOKEN 是自动提供的，你不需要手动设置它。但如果你需要设置其他自定义变量，你可以通过 GitHub 仓库的 Settings 来设置。以下是设置步骤：

打开你的 GitHub 仓库
点击顶部的 "Settings" 标签
在左侧菜单中，点击 "Secrets and variables" 下的 "Actions"
在这里你可以添加两种类型的变量：
"Secrets": 用于敏感信息（加密存储）
"Variables": 用于非敏感信息（明文存储）
要在 GitHub Actions 工作流中使用这些变量：

对于 Secrets: ${{ secrets.YOUR_SECRET_NAME }}
对于 Variables: ${{ vars.YOUR_VARIABLE_NAME }}
在你的 deploy.yml 中，已经在使用 GITHUB_TOKEN secret：

#### 修改完 部署到 GitHub pages

git add . && git commit -m "update" && git push -u origin main

