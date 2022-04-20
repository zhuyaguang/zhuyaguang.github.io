# Kubeflow实践笔记


# 基于 Kubernetes 的云原生 AI 平台建设

### 提高算力资源利用

1. GPU 虚拟化

 GPUManager 基于 GPU 驱动封装实现，用户需要对驱动的某些关键接口（如显存分配、cuda thread 创建等）进行封装劫持，在劫持过程中限制用户进程对计算资源的使用，整体方案较为轻量化、性能损耗小，自身只有 5% 的性能损耗，支持同一张卡上容器间 GPU 和显存使用隔离，保证了编码这种算力利用率不高的场景开发者可以共享 GPU，同时在同一块调试时资源不会被抢占。

2. 训练集群算力调度

在 Kubernetes 里面使用 Job 来创建训练任务，只需要指定需要使用的GPU资源，结合消息队列，训练集群算力资源利用率可以达到满载。

3. 资源监控

资源监控对集群编码、训练优化有关键指导作用，可以限制每个项目 GPU 总的使用量和每个用户GPU 资源分配。

![img](https://miro.medium.com/max/1400/1*LhL7j9QhwgQCO4bMu-CNjw.jpeg)

### kubeflow介绍

Kubeflow 是 google 开发的包含了机器学习模型开发生命周期的开源平台。 Kubeflow 由一组工具组成，这些工具解决了机器学习生命周期中的每个阶段，例如：数据探索、特征工程、特征转换、模型实验、模型训练、模型评估、模型调整、模型服务和 模型版本控制。 kubeflow 的主要属性是它被设计为在 kubernetes 之上工作，也就是说，kubeflow 利用了 kubernetes 集群提供的好处，例如容器编排和自动扩展。

![An architectural overview of Kubeflow on Kubernetes](https://www.kubeflow.org/docs/images/kubeflow-overview-platform-diagram.svg)



### Kubeflow components in the ML workflow

![Where Kubeflow fits into a typical machine learning workflow](https://www.kubeflow.org/docs/images/kubeflow-overview-workflow-diagram-2.svg)





### 安装 kubeflow

#### todo





### kubeflow学习指南笔记

> [本书代码地址](https://github.com/intro-to-ml-with-kubeflow/intro-to-ml-with-kubeflow-examples)



#### 设置镜像仓库

Kaniko配置指南：https://github.com/GoogleContainerTools/kaniko#pushing-to-different-registries

#### 创建一个 kubeflow 项目，手写数字识别

模型查询示例代码： https://github.com/intro-to-ml-with-kubeflow/intro-to-ml-with-kubeflow-examples/blob/master/ch2/query-endpoint.py

```python
import requests
import numpy as np

from tensorflow.examples.tutorials.mnist import input_data
from matplotlib import pyplot as plt

def download_mnist():
    return input_data.read_data_sets("MNIST_data/", one_hot=True)


def gen_image(arr):
    two_d = (np.reshape(arr, (28, 28)) * 255).astype(np.uint8)
    plt.imshow(two_d, cmap=plt.cm.gray_r, interpolation='nearest')
    return plt
#end::scriptSetup[]

AMBASSADOR_API_IP = "10.53.148.167:30134"

#tag::scriptGuts[]
mnist = download_mnist()
batch_xs, batch_ys = mnist.train.next_batch(1)
chosen = 0
gen_image(batch_xs[chosen]).show()
data = batch_xs[chosen].reshape((1, 784))
features = ["X" + str(i + 1) for i in range(0, 784)]
request = {"data": {"names": features, "ndarray": data.tolist()}}
deploymentName = "mnist-classifier"
uri = "http://" + AMBASSADOR_API_IP + "/seldon/" + \
    deploymentName + "/api/v0.1/predictions"

response = requests.post(uri, json=request)
#end::scriptGuts[]
print(response.status_code)
```

#### kubeflow 设计

[训练 operator汇总](https://www.kubeflow.org/docs/components/training/)

#### Pipeline

pipeline本质上是一个容器执行的图，除了指定哪些容器以何种顺序运行之外，它还允许用户向整个pipeline传递参数和在容器之间传递参数。

每一个pipeline包含下面四个必要步骤

1.创建容器 2.创建一个操作 3.对操作进行排序 4.输出为可执行的YAML文件



#### pipeline 基本例子

```python
#!/usr/bin/env python
# coding: utf-8


import kfp
from kfp import compiler
import kfp.dsl as dsl
import kfp.notebook
import kfp.components as comp



#Define a Python function
def add(a: float, b: float) -> float:
    '''Calculates sum of two arguments'''
    return a + b


add_op = comp.func_to_container_op(add)


from typing import NamedTuple


def my_divmod(
    dividend: float, divisor: float
) -> NamedTuple('MyDivmodOutput', [('quotient', float), ('remainder', float)]):
    '''Divides two numbers and calculate  the quotient and remainder'''
    #Imports inside a component function:
    import numpy as np

    #This function demonstrates how to use nested functions inside a component function:
    def divmod_helper(dividend, divisor):
        return np.divmod(dividend, divisor)

    (quotient, remainder) = divmod_helper(dividend, divisor)

    from collections import namedtuple
    divmod_output = namedtuple('MyDivmodOutput', ['quotient', 'remainder'])
    return divmod_output(quotient, remainder)


divmod_op = comp.func_to_container_op(
    my_divmod, base_image='tensorflow/tensorflow:1.14.0-py3')


@dsl.pipeline(
    name='Calculation pipeline',
    description='A toy pipeline that performs arithmetic calculations.')
def calc_pipeline(
    a='a',
    b='7',
    c='17',
):
    #Passing pipeline parameter and a constant value as operation arguments
    add_task = add_op(a, 4)  # Returns a dsl.ContainerOp class instance.

    #Passing a task output reference as operation arguments
    #For an operation with a single return value, the output reference can be accessed using `task.output` or `task.outputs['output_name']` syntax
    divmod_task = divmod_op(add_task.output, b)

    #For an operation with a multiple return values, the output references can be accessed using `task.outputs['output_name']` syntax
    result_task = add_op(divmod_task.outputs['quotient'], c)


if __name__ == '__main__':
    # Compiling the pipeline
    kfp.compiler.Compiler().compile(calc_pipeline, 'ch04.yaml')
```



#### 步骤之间存储数据

kubeflow Pipeline 的 volumeOp 允许创建一个自动管理的持久卷。

```python
dvop = dsl.volumeOp(name="create_pvc",resource_name="my-pvc-2",size="5Gi",modes=dsl.VOLUME_MODE_RWO)

```



还可以利用 MinIO 把文件写入容器本地，并在ContainerOp中指定参数

```python
fetch = kfp.dsl.ContainerOp(
    name="download",
    command=['sh','-c'],
    arguments=[
        'sleep 1;'
        'mkdir -p /tmp/data;'
        'wget '+ data_url +' -O /tmp/data/result.csv'
    ],
    file_outputs={'downloaded':'/tmp/data'}
)
```



#### func_to_container

[标准组件库](https://github.com/kubeflow/pipelines/tree/master/components)



#### Pipeline 高级主题

1. [复杂条件判断](https://github.com/kubeflow/pipelines/blob/master/samples/tutorials/DSL%20-%20Control%20structures/DSL%20-%20Control%20structures.py)
2. 定期执行pipeline，使用recurring



#### 数据准备和特征准备

[2022数据准备工具列表](https://solutionsreview.com/data-integration/the-best-data-preparation-tools-and-software/)



#### 元数据

[ML Metadata](https://github.com/google/ml-metadata/blob/master/g3doc/get_started.md)



### 训练机器学习模型

[用户购买记录数据][https://github.com/moorissa/medium/tree/master/items-recommender/data]

Notebook 基础镜像：tensorflow-1.15.2-notebook-cpu:1.0.0





### code

```python
#!/usr/bin/env python
# coding: utf-8

# In[ ]:

from transformers import (
    BertConfig,
    BertTokenizer,
    BertForMaskedLM,
    DataCollatorForWholeWordMask,
    Trainer,
    TrainingArguments,
    LineByLineWithRefDataset
)
import torch
import tokenizers
import argparse

def main(args):

    tokenizer_kwargs = {
        "model_max_length": 512
    }
    
    tokenizer =  BertTokenizer.from_pretrained('/home/hdu-sunhao/孙浩/二次训练_nezha/', **tokenizer_kwargs)
    
    config_new = BertConfig.from_pretrained(args.config)
    
    model = BertForMaskedLM.from_pretrained(args.model, config=config_new)
    
    model.resize_token_embeddings(len(tokenizer))  
                            
    train_dataset = LineByLineWithRefDataset(tokenizer = tokenizer,file_path = args.file_path, ref_path = args.ref_path, block_size=512)      
            
    data_collator = DataCollatorForWholeWordMask(tokenizer=tokenizer, mlm=True, mlm_probability=0.15)
    
    pretrain_batch_size=16
    num_train_epochs=5
    training_args = TrainingArguments(
        output_dir='/home/hdu-sunhao/孙浩/二次训练_nezha/model-claims/args', overwrite_output_dir=True, num_train_epochs=num_train_epochs, 
        learning_rate=1e-4, weight_decay=0.01, warmup_steps=10000, local_rank = args.local_rank, #dataloader_pin_memory = False,
        per_device_train_batch_size=pretrain_batch_size, logging_strategy ="epoch",save_strategy = "epoch", save_total_limit = 1)
    
    trainer = Trainer(
        model=model, args=training_args, data_collator=data_collator, train_dataset=train_dataset)
    
    trainer.train()
    trainer.save_model(args.save_dir)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="nezha_train")
    parser.add_argument("--config", type = str, default = None, help = "二次训练_nezha")
    parser.add_argument("--model", type = str, default = None, help = "二次训练_nezha")
    parser.add_argument("--file_path", type = str, default = None, help = "二次训练_nezha")
    parser.add_argument("--ref_path", type = str, default = None, help = "二次训练_nezha")
    parser.add_argument("--save_dir", type = str, default = None, help = "二次训练_nezha")
    parser.add_argument("--local_rank", type = int, default = -1, help = "For distributed training: local_rank")
    args = parser.parse_args()
    main(args)
```




