---
title: "Gitlab Printer"
date: 2022-09-05T16:19:39+08:00
draft: true
---



# 我用 **极狐** Gitlab 议题 来点菜



虽然我是一个程序员，但是我一直想开一个餐厅。希望开一个极客范儿的餐厅，大家通过 issue 来点菜。受到推特上一位[大佬 *Andrew Schmelyun* 的影响](https://aschmelyun.com/blog/i-built-a-receipt-printer-for-github-issues/)，我在 Gitlab 上实现了该功能。

话不多说，先看看效果。



<iframe src="//player.bilibili.com/player.html?bvid=BV1fP4y1f7CZ&cid=824450453&page=1" scrolling="no" border="0" frameborder="no" framespacing="0"></iframe>



接下来，我来介绍下是怎么实现的。



## 硬件列表

* 打印机
* Mac（可以换成树莓派）

我这里是惠普的普通办公打印机，换成那种打印小票的热敏打印机效果更好。纸张更小，可以夹在后厨。

![FOoPxp5WUAUwzqs](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/FOoPxp5WUAUwzqs.png)

我这里是用 Mac 直接连接添加的网络打印机，可以通过 `lp filename` 直接打印文件。

![image-20220905130647468](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20220905130647468.png)

## 发送数据给打印机

作为一个 Go 的开发者，很容易就想到用 Gin 框架起一个 http 服务。用来接受 客户的菜单请求。

```go
func main() {


	router := gin.New()

	// post请求
	router.POST("/postReq", func(ctx *gin.Context) {


		var req GitlabIssue
		err := ctx.ShouldBindJSON(&req) // 解析req参数
		if err != nil {
			fmt.Println("ctx.ShouldBindJSON err: ", err)
			return
		}


		rspMap := map[string]interface{}{ // 也可用结构体方式返回
			"code": 0,
			"rsp":  fmt.Sprintf("welcome %v!", req.User.Name),
		}

		ctx.JSON(http.StatusOK, rspMap)
		fmt.Printf("rsp: %+v\n", rspMap)
		writeMemu(req.ObjectAttributes.Title+"\n"+req.ObjectAttributes.Description)
		cmdShell()
	})

	router.Run(":8080") // 8080端口，底层调用的是net/http包，也是单独启协程进行监听

	return

}
```

打印菜单命令，菜单保存在 `memu.txt` 文件中。

```go
func cmdShell() {

	cmd := exec.Command("lp","memu.txt")
	stdout, err := cmd.Output()

	if err != nil {
		fmt.Println("error======",err.Error())
		return
	}

	// Print the output
	fmt.Println(string(stdout))
}

func writeMemu(memu string)  {
	f, err := os.Create("memu.txt")

	if err != nil {
		log.Fatal(err)
	}

	defer f.Close()

	_, err2 := f.WriteString(memu)

	if err2 != nil {
		log.Fatal(err2)
	}

	fmt.Println("done")
}
```

其中  GitlabIssue 结构体的构造可以参考 Gitlab 文档上关于  [Webhook 事件的例子]( https://docs.gitlab.cn/jh/user/project/integrations/webhook_events.html)，来构造 议题 请求的结构体。

```go
type GitlabIssue struct {
	ObjectKind string `json:"object_kind"`
	EventType  string `json:"event_type"`
	User       struct {
		ID        int    `json:"id"`
		Name      string `json:"name"`
		Username  string `json:"username"`
		AvatarURL string `json:"avatar_url"`
		Email     string `json:"email"`
	} `json:"user"`
	ObjectAttributes struct {
		ID                  int         `json:"id"`
		Title               string      `json:"title"`
		AssigneeIds         []int       `json:"assignee_ids"`
		AssigneeID          int         `json:"assignee_id"`
```

关于 json 怎么转结构体，可以参考[该连接](https://mholt.github.io/json-to-go/)

`go run main.go` 服务就在本地的 8080 端口起来了。

![image-20220905131952437](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20220905131952437.png)

## 链接 Gitlab

### 添加 Webhooks

这个时候，发送一个 curl 请求，就可以调试打印了。但是想要从 Gitlab 议题触发，就要用到 Gitlab 的 Webhooks 。Gitlab Webhooks 使用起来也很方便。进入 **设置**---**Webhooks**，输入要请求的 URL 和出发事件。

![image-20220905133002737](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20220905133002737.png)



### 需要允许对本地网络的请求

 由于本地网络上运行非 GitLab Web 服务，则这些服务可能容易受到 Webhook 的利用。所以要允许对本地网络的请求。

1. 在顶部栏上，选择 **菜单 > 管理员**。
2. 在左侧边栏中，选择 **设置 > 网络**。
3. 展开 **出站请求** 部分：[![Outbound requests admin settings](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/outbound_requests_section_v12_2.png)](https://docs.gitlab.cn/jh/security/img/outbound_requests_section_v12_2.png)
4. 选择 **允许来自 web hooks 和服务对本地网络的请求**。

### 添加本地请求的许可名单

1. 在顶部栏上，选择 **菜单 > 管理员**。
2. 在左侧边栏中，选择 **设置 > 网络** (`/admin/application_settings/network`) ，输入以下内容，允许本地服务

```shell
127.0.0.1,1:0:0:0:0:0:0:1
127.0.0.0/8 1:0:0:0:0:0:0:0/124
[1:0:0:0:0:0:0:1]:8080
127.0.0.1:8080
```

具体设置可以参考[官网文档](https://docs.gitlab.cn/jh/security/webhooks.html)

更多 Webhooks 用法可以参考[链接](https://docs.gitlab.cn/jh/user/project/integrations/webhooks.html#configure-a-webhook-in-gitlab)

## 内网穿透

由于服务是本地的，需要顾客点菜，所以需要其他人可以访问该网络，最简单做法就是使用 ngrok

```
ngrok http 8080
```

![image-20220905134251296](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20220905134251296.png)



`Webhooks ` 网址就填写：`https://e9b1-61-164-43-2.jp.ngrok.io/postReq`

## 完整代码

完整代码已经放在了 极狐 Gitlab上了

源码地址：https://jihulab.com/zyg/Restaurant/-/tree/dev-zyg

## 后期规划

* 新增二维码点餐，可以扫描二维码进入 Gitlab issue 界面，填写 issue 点菜。
* 硬件小型化，打印机打算去咸鱼淘一个热敏打印机，打印纸也比较小。服务打算部署在树莓派上。



## 参考链接

https://aschmelyun.com/blog/i-built-a-receipt-printer-for-github-issues/

https://docs.gitlab.cn/jh/user/project/integrations/webhooks.html#configure-a-webhook-in-gitlab
