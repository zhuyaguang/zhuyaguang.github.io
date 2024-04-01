# 基于 kubesphere 和 kubeedge 在 Jetson 上运行 GPU 应用（docker/containerd）



# 在轨验证方案

##  应用的部署流程图

![image-20240315111505144](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20240315111505144.png)



> 在 Jetson 上 如果部署 GPU 类型的应用，需要有  NVIDIA Container Runtime 支持。

![img](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/_images/runtime-architecture.png)

[NVIDIA Container Runtime](https://developer.nvidia.com/container-runtime#)



## 环境配置

各个组件的版本信息如下：

| 组件       | 版本                               |
| ---------- | ---------------------------------- |
| kubesphere | 3.4.1                              |
| containerd | 1.7.2                              |
| k8s        | 1.26.0                             |
| kubeedge   | 1.15.1                             |
| Jetson型号 | NVIDIA Jetson Xavier NX (16GB ram) |
| Jtop       | 4.2.7                              |
| JetPack    | 5.1.3-b29                          |
| docker     | 24.0.5                             |

### 安装jtop

> 安装 jtop 的目的是为了监控 GPU 的使用情况

```
sudo apt-get install python3-pip python3-dev -y
sudo -H pip3 install jetson-stats
sudo systemctl restart jtop.service
```



![image-20240311094852620](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20240311094852620.png)



### 安装JetPack

* 什么是 JetPack （https://developer.nvidia.com/embedded/develop/software）

> The Jetson software stack begins with NVIDIA JetPack™ SDK, which provides Jetson Linux, developer tools, and CUDA-X accelerated libraries and other NVIDIA technologies.
>
> JetPack enables end-to-end acceleration for your AI applications, with NVIDIA TensorRT and cuDNN for accelerated AI inferencing, CUDA for accelerated general computing, VPI for accelerated computer vision and image processing, Jetson Linux API’s for accelerated multimedia, and libArgus and V4l2 for accelerated camera processing.
>
> NVIDIA container runtime is also included in JetPack, enabling cloud-native technologies and workflows at the edge. Transform your experience of developing and deploying software by containerizing your AI applications and managing them at scale with cloud-native technologies.
>
> Jetson Linux provides the foundation for your applications with a Linux kernel, bootloader, NVIDIA drivers, flashing utilities, sample filesystem, and toolchains for the Jetson platform. It also includes security features, over-the-air update capabilities and much more.
>
> JetPack will soon come with a collection of system services which are fundamental capabilities for building edge AI solutions. These services will simplify integration into developer workflows and spare them the arduous task of building them from the ground up.

* JetPack 组成

![image-20240313140009928](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20240313140009928.png)

* 安装命令

```
sudo apt update
sudo apt install nvidia-jetpack

sudo apt show nvidia-jetpack
```

参考文档：[NVIDIA JetPack Documentation](https://docs.nvidia.com/jetson/jetpack/index.html)

* 无法安装，请更换镜像源

> ```shell
> Please edit your nvidia-l4t-apt-source.list to r34.1:
> 
> deb https://repo.download.nvidia.com/jetson/common r34.1 main
> deb https://repo.download.nvidia.com/jetson/t234 r34.1 main
> Run below command to upgrade and install sdk components:
> sudo apt dist-upgrade
> sudo reboot
> sudo apt install nvidia-jetpack
> ```



### 地卫二 Jetson安装组件版本信息

![image-20240313104210233](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20240313104210233.png)

* nvidia-ctk 版本信息：NVIDIA Container Toolkit CLI version 1.11.0-rc.1

* jetpack 版本信息

  ![image-20240313104318867](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20240313104318867.png)



### 安装 Docker 打镜像包

nvidia 在 jetson 上对 containerd 运行时支持不太友好，有些算法在containerd 运行会出现错误， 在普通的 GPU 服务器上是可以完美支持 containerd 运行 。

另外 containerd 打镜像也需要 docker build  来支持。Docker  可以不用安装在 Jetson 机器上，可以准备一台专门打镜像的机器。



![image-20240312174619755](C:\Users\DELL\AppData\Roaming\Typora\typora-user-images\image-20240312174619755.png)

[Cloud-Native on Jetson](https://developer.nvidia.com/embedded/jetson-cloud-native)





![image-20240312180127250](C:\Users\DELL\AppData\Roaming\Typora\typora-user-images\image-20240312180127250.png)





```
sudo apt-get update
sudo apt-get install \
apt-transport-https \
ca-certificates \
curl \
gnupg \
lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null


sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io

```

### Nvida 官方的机器学习 docker 镜像

![image-20240313090907773](C:\Users\DELL\AppData\Roaming\Typora\typora-user-images\image-20240313090907773.png)



其中 **l4t-base container** 是基础镜像，可以在此基础上构建自己所需的镜像。

例如：

```dockerfile
FROM nvcr.io/nvidia/l4t-base:r32.4.2
WORKDIR /
RUN apt update && apt install -y --fix-missing make g++ python3-pip libhdf5-serial-dev hdf5-tools libhdf5-dev \
        zlib1g-dev zip libjpeg8-dev liblapack-dev libblas-dev gfortran python3-h5py && \
    pip3 install --no-cache-dir --upgrade pip  && \
    pip3 install --no-cache-dir --upgrade testresources setuptools cython && \
    pip3 install --pre --no-cache-dir --extra-index-url https://developer.download.nvidia.com/compute/redist/jp/v44 tensorflow && \
    apt-get clean

CMD [ "bash" ]
```

## 应用部署

### 部署 mnist 算法

#### mnist 镜像准备

* pytorch 训练代码

```python
from __future__ import print_function
import argparse
import torch
import torch.nn as nn
import torch.nn.functional as F
import torch.optim as optim
from torchvision import datasets, transforms
from torch.optim.lr_scheduler import StepLR


class Net(nn.Module):
    def __init__(self):
        super(Net, self).__init__()
        self.conv1 = nn.Conv2d(1, 32, 3, 1)
        self.conv2 = nn.Conv2d(32, 64, 3, 1)
        self.dropout1 = nn.Dropout(0.25)
        self.dropout2 = nn.Dropout(0.5)
        self.fc1 = nn.Linear(9216, 128)
        self.fc2 = nn.Linear(128, 10)

    def forward(self, x):
        x = self.conv1(x)
        x = F.relu(x)
        x = self.conv2(x)
        x = F.relu(x)
        x = F.max_pool2d(x, 2)
        x = self.dropout1(x)
        x = torch.flatten(x, 1)
        x = self.fc1(x)
        x = F.relu(x)
        x = self.dropout2(x)
        x = self.fc2(x)
        output = F.log_softmax(x, dim=1)
        return output


def train(args, model, device, train_loader, optimizer, epoch):
    model.train()
    for batch_idx, (data, target) in enumerate(train_loader):
        data, target = data.to(device), target.to(device)
        optimizer.zero_grad()
        output = model(data)
        loss = F.nll_loss(output, target)
        loss.backward()
        optimizer.step()
        if batch_idx % args.log_interval == 0:
            print('Train Epoch: {} [{}/{} ({:.0f}%)]\tLoss: {:.6f}'.format(
                epoch, batch_idx * len(data), len(train_loader.dataset),
                100. * batch_idx / len(train_loader), loss.item()))
            if args.dry_run:
                break


def test(model, device, test_loader):
    model.eval()
    test_loss = 0
    correct = 0
    with torch.no_grad():
        for data, target in test_loader:
            data, target = data.to(device), target.to(device)
            output = model(data)
            test_loss += F.nll_loss(output, target, reduction='sum').item()  # sum up batch loss
            pred = output.argmax(dim=1, keepdim=True)  # get the index of the max log-probability
            correct += pred.eq(target.view_as(pred)).sum().item()

    test_loss /= len(test_loader.dataset)

    print('\nTest set: Average loss: {:.4f}, Accuracy: {}/{} ({:.0f}%)\n'.format(
        test_loss, correct, len(test_loader.dataset),
        100. * correct / len(test_loader.dataset)))


def main():
    # Training settings
    parser = argparse.ArgumentParser(description='PyTorch MNIST Example')
    parser.add_argument('--batch-size', type=int, default=64, metavar='N',
                        help='input batch size for training (default: 64)')
    parser.add_argument('--test-batch-size', type=int, default=1000, metavar='N',
                        help='input batch size for testing (default: 1000)')
    parser.add_argument('--epochs', type=int, default=14, metavar='N',
                        help='number of epochs to train (default: 14)')
    parser.add_argument('--lr', type=float, default=1.0, metavar='LR',
                        help='learning rate (default: 1.0)')
    parser.add_argument('--gamma', type=float, default=0.7, metavar='M',
                        help='Learning rate step gamma (default: 0.7)')
    parser.add_argument('--no-cuda', action='store_true', default=False,
                        help='disables CUDA training')
    parser.add_argument('--no-mps', action='store_true', default=False,
                        help='disables macOS GPU training')
    parser.add_argument('--dry-run', action='store_true', default=False,
                        help='quickly check a single pass')
    parser.add_argument('--seed', type=int, default=1, metavar='S',
                        help='random seed (default: 1)')
    parser.add_argument('--log-interval', type=int, default=10, metavar='N',
                        help='how many batches to wait before logging training status')
    parser.add_argument('--save-model', action='store_true', default=False,
                        help='For Saving the current Model')
    args = parser.parse_args()
    use_cuda = not args.no_cuda and torch.cuda.is_available()
    use_mps = not args.no_mps and torch.backends.mps.is_available()

    torch.manual_seed(args.seed)

    if use_cuda:
        device = torch.device("cuda")
    elif use_mps:
        device = torch.device("mps")
    else:
        device = torch.device("cpu")

    train_kwargs = {'batch_size': args.batch_size}
    test_kwargs = {'batch_size': args.test_batch_size}
    if use_cuda:
        cuda_kwargs = {'num_workers': 1,
                       'pin_memory': True,
                       'shuffle': True}
        train_kwargs.update(cuda_kwargs)
        test_kwargs.update(cuda_kwargs)

    transform=transforms.Compose([
        transforms.ToTensor(),
        transforms.Normalize((0.1307,), (0.3081,))
        ])
    dataset1 = datasets.MNIST('../data', train=True, download=True,
                       transform=transform)
    dataset2 = datasets.MNIST('../data', train=False,
                       transform=transform)
    train_loader = torch.utils.data.DataLoader(dataset1,**train_kwargs)
    test_loader = torch.utils.data.DataLoader(dataset2, **test_kwargs)

    model = Net().to(device)
    optimizer = optim.Adadelta(model.parameters(), lr=args.lr)

    scheduler = StepLR(optimizer, step_size=1, gamma=args.gamma)
    for epoch in range(1, args.epochs + 1):
        train(args, model, device, train_loader, optimizer, epoch)
        test(model, device, test_loader)
        scheduler.step()

    if args.save_model:
        torch.save(model.state_dict(), "mnist_cnn.pt")


if __name__ == '__main__':
    main()
```

* Dockerfile 打镜像，基于 nvidia 的 pytorch 基础镜像

  ```dockerfile
  FROM nvcr.io/nvidia/l4t-pytorch:r35.2.1-pth2.0-py3 
    
  COPY pytorch-mnist.py /home/ 
  ```

`docker build -t mnist:1.0 .`

docker 运行命令：

不加 --runtime nvidia 参数，会使用 CPU 进行训练

```shell
docker run -it --runtime nvidia mnist:1.0  /bin/bash
python3 pytorch-minst.py
```

* 不打镜像直接挂载代码

  ```shell
  sudo docker run -it --rm --runtime nvidia --network host -v /home/user/project:/location/in/container nvcr.io/nvidia/l4t-pytorch:r35.2.1-pth2.0-py3
  
  python3 pytorch-minst.py
  ```

* 镜像转换

  **当然如果安装了 Harbor 镜像仓库，直接 docker push 然后 ctr images pull** 

```shell
docker save nvcr.io/nvidia/l4t-pytorch:r35.2.1-pth2.0-py3 -o pytorch.tar
 
ctr -n k8s.io images import pytorch.tar
```

* containerd 运行命令：

```shell
ctr c create nvcr.io/nvidia/l4t-pytorch:r35.2.1-pth2.0-py3 gpu-demo

ctr task start -d gpu-demo

ctr task exec --exec-id 2 -t gpu-demo sh

python3 pytorch-minst.py

ctr tasks kill gpu-demo --signal SIGKILL

或者

ctr run --rm --gpus 0 --tty local-harbor.com/algorithms/mnist:1.0 python3 /home/pytorch-mnist.py
```

#### pod部署

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: gpu-test
spec:
  hostNetwork: true
  nodeSelector:
    kubernetes.io/hostname: jetpack513-desktop
  containers:
  - image: local-harbor.com/algorithms/mnist:1.0
    imagePullPolicy: IfNotPresent
    name: gpu-test
    command:
    - "/bin/bash"
    - "-c"
    - "python3 /home/pytorch-mnist.py"
  restartPolicy: Never
```



#### deployment 部署

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gpu-test
  labels:
    app: gpu-test
spec:
  replicas: 1
  selector:
    matchLabels:
      app: gpu-test
  template:
    metadata:
      labels:
        app: gpu-test
    spec:
      hostNetwork: true
      containers:
      - name: gpu-test
        image: local-harbor.com/algorithms/mnist:1.0
        imagePullPolicy: IfNotPresent
        command:
        - "/bin/bash"
        - "-c"
        - "python3 /home/pytorch-mnist.py"
    strategy:
      type: RollingUpdate
      rollingUpdate:
        maxUnavailable: 25%
        maxSurge: 25%
```

### 部署 高分算法

* Dockerfile-arm

  whl 文件比较大，需要从指定目录拷贝过来。

  ```dockerfile
  # 使用官方的Python基础镜像
  # FROM python:3.8
  FROM python:3.8-slim
  
  # # 安装OpenCV依赖
  RUN apt-get update
  # libjasper-dev libdc1394-22-dev libavresample-dev \
  RUN apt-get install -y --no-install-recommends \
      build-essential \
      cmake \
      git \
      pkg-config \
      libjpeg-dev \
      libtiff5-dev \    
      libpng-dev \
      zlib1g-dev libopenexr-dev libgdal-dev \
      gdal-bin \
      libavcodec-dev \
      libavformat-dev \
      libswscale-dev \
      libv4l-dev \
      libxvidcore-dev \
      libx264-dev \
      libgtk-3-dev libcanberra-gtk* \
      libatlas-base-dev  libhdf5-dev liblapacke-dev libblas-dev \
      gfortran \
      ffmpeg \
      python3-dev python3-pip
  
  
  # 复制PyTorch安装文件到镜像中 这里面的镜像文件
  COPY torch-1.10.0-cp38-cp38-manylinux2014_aarch64.whl /tmp/torch-1.10.0-cp38-cp38-manylinux2014_aarch64.whl
  COPY torchvision-0.11.0-cp38-cp38-manylinux2014_aarch64.whl /tmp/torchvision-0.11.0-cp38-cp38-manylinux2014_aarch64.whl
  COPY torchaudio-0.10.0-cp38-cp38-manylinux2014_aarch64.whl /tmp/torchaudio-0.10.0-cp38-cp38-manylinux2014_aarch64.whl
  COPY scipy-1.8.0-cp38-cp38-manylinux_2_17_aarch64.manylinux2014_aarch64.whl /tmp/scipy-1.8.0-cp38-cp38-manylinux_2_17_aarch64.manylinux2014_aarch64.whl
  COPY opencv_python-4.9.0.80-cp37-abi3-manylinux_2_17_aarch64.manylinux2014_aarch64.whl /tmp/opencv_python-4.9.0.80-cp37-abi3-manylinux_2_17_aarch64.manylinux2014_aarch64.whl
  # 安装PyTorch
  RUN pip install --upgrade pip
  RUN pip install Pillow==10.2.0
  RUN pip install numpy==1.24.4
  RUN pip install /tmp/torch-1.10.0-cp38-cp38-manylinux2014_aarch64.whl
  RUN pip install /tmp/torchvision-0.11.0-cp38-cp38-manylinux2014_aarch64.whl
  RUN pip install /tmp/torchaudio-0.10.0-cp38-cp38-manylinux2014_aarch64.whl
  RUN pip install /tmp/scipy-1.8.0-cp38-cp38-manylinux_2_17_aarch64.manylinux2014_aarch64.whl
  RUN pip install /tmp/opencv_python-4.9.0.80-cp37-abi3-manylinux_2_17_aarch64.manylinux2014_aarch64.whl
  
  
  RUN pip install gitpython==3.1.42
  RUN pip install setuptools==69.2.0
  RUN pip install tiffile
  RUN pip install GDAL==3.6.2
  RUN pip install ultralytics
  
  
  
  # # 将您的算法代码复制到容器中
  COPY GaoFen-2_ortho.py /app/GaoFen-2_ortho.py
  COPY GF2_PMS1_E139.8_N35.5_20230109_L1A0007045334-MSS1.rpb /app/GF2_PMS1_E139.8_N35.5_20230109_L1A0007045334-MSS1.rpb
  COPY GF2_PMS1_E139.8_N35.5_20230109_L1A0007045334-MSS1.tiff /app/GF2_PMS1_E139.8_N35.5_20230109_L1A0007045334-MSS1.tiff
  COPY GMTED2010.jp2 /app/GMTED2010.jp2
  # 给予执行权限
  RUN chmod +x GaoFen-2_ortho.py
  
  ```



#### job 部署，用算法基础镜像

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: tianji-job3
  labels:
    jobgroup: jobexample
spec:
  template:
    metadata:
      name: kubejob
      labels:
        jobgroup: jobexample
    spec:
      nodeName: jetpack513
      containers:
      - name: tianji-c3
        image: armtianji:v1
        command: ["/bin/sh", "-c"]      
        args: ["python /app/GaoFen-2_ortho.py"]   
        imagePullPolicy: IfNotPresent
        volumeMounts:
        - name: app
          mountPath: /app       
      volumes:
      - name: app
        hostPath:
          path: /home/jetpack511/zyg/algorithms/Gaofen
      restartPolicy: Never
```

其中 `path: /home/jetpack511/zyg/algorithms/Gaofen` 为 gitlab 下载的代码存放地址

#### job 部署，用高分算法镜像

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: gaofen-job
  labels:
    jobgroup: jobexample
spec:
  template:
    metadata:
      name: kubejob
      labels:
        jobgroup: jobexample
    spec:
      nodeName: edge1
      containers:
      - name: tianji-c3
        image: local-harbor.com/algorithms/gaofen:v1
        command: ["/bin/sh", "-c"]      
        args: ["python /app/GaoFen-2_ortho.py"]   
        imagePullPolicy: IfNotPresent
      restartPolicy: Never
```

#### 制作 chart 包，上架应用市场

* 安装 Helm ，具体参考[官网](https://helm.sh/zh/docs/)
* helm create gaofen 新建模板
* rm -rf gaofen/templates/* 替换k8s资源文件，将 job.yaml  放进去
*  helm install gaofen2024 ./gaofen 安装应用
* helm uninstall gaofen2024  卸载应用

修改 Values.yaml 外部传入变量

```yaml
name: gaofen-2024
images: local-harbor.com/algorithms/gaofen:v1
```

job.yaml

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ .Values.name }}
  labels:
    jobgroup: jobexample
spec:
  template:
    metadata:
      name: kubejob
      labels:
        jobgroup: jobexample
    spec:
      nodeName: edge1
      containers:
      - name: tianji-c3
        image: {{ .Values.images }}
        command: ["/bin/sh", "-c"]      
        args: ["python /app/GaoFen-2_ortho.py"]   
        imagePullPolicy: IfNotPresent
      restartPolicy: Never
```

* 打包 `helm package gaofen/`

### UI 界面部署

> 需要创建一个企业空间、一个项目以及一个用户 (`project-regular`)

1. 登录该用户账号，上传应用模板

![image-20240326143428655](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20240326143428655.png)

2. 每个算法的代码仓库里面，会有一个自动打包好的 chart 包（应用安装包）

![image-20240326143922245](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20240326143922245.png)

3. 上传应用的图标

![image-20240326144231886](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20240326144231886.png)

4. 安装应用，选择项目（命名空间）

![image-20240326144552140](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20240326144552140.png)

5. 配置应用参数，选择应用部署的卫星节点。

   ![image-20240326144644944](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20240326144644944.png)

   6. 部署后，可以查看应用实例

      ![image-20240326145121877](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20240326145121877.png)



#### 应用发布

* 应用还可以提交发布给其他人使用

![image-20240326145341039](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20240326145341039.png)

* 管理员审核通过后，可以上架到公共的应用商店

![image-20240326145424545](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20240326145424545.png)



具体应用生命周期管理，可以参考[链接](https://kubesphere.io/zh/docs/v3.3/application-store/app-lifecycle-management/)

## 参考文档

nvidia-ctk安装教程：[Installing the NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html#installing-the-nvidia-container-toolkit)

安装有问题可以参考：[Trobleshooting](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/troubleshooting.html)

[nvidia-docker 与 nvidia container runtime 的区别](https://github.com/NVIDIA/nvidia-docker/issues/1268)

