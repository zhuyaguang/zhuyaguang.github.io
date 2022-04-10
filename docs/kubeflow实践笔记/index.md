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



### Kubeflow user interface (UI)

![image-20220328102313469](/Users/zhuyaguang/Library/Application Support/typora-user-images/image-20220328102313469.png)

http://10.101.32.26:8080/

### 

### Distributed training with Kubeflow pipeline

https://github.com/kubeflow/examples/tree/master/FaceNet-distributed-training

![img](https://user-images.githubusercontent.com/51089749/137869771-50941659-9fc1-450f-ae2a-5628d9b80d2d.png)





### Natural-Language-Processing

https://github.com/dfm871002/examples/blob/master/Natural-Language-Processing/3.%20Jupyter%20Notebook/Jupyter%20Notebook.md



![pipeline](https://github.com/dfm871002/examples/raw/master/Natural-Language-Processing/4.%20Image/pipeline.png)



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




