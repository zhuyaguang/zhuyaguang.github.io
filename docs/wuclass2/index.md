# 吴恩达-使用ChatGPT API构建系统-笔记




# 使用ChatGPT API构建系统



## Language Models, the Chat Format and Tokens



翻转字符串得到的结果不对，因为大模型是根据 token 来预测下一个单词的，而不是 word。

```python
response = get_completion("Take the letters in lollipop \
and reverse them")
```

* token 的定义

![image-20230602094959196](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20230602094959196.png)



```python
response = get_completion("""Take the letters in \
l-o-l-l-i-p-o-p and reverse them""")
```

加了横杠就可以了。



### chat format 工作原理

你可以在 system 指定 风格和长度或者全制定

```python
messages =  [  
{'role':'system', 
 'content':"""You are an assistant who\
 responds in the style of Dr Seuss."""},    
{'role':'user', 
 'content':"""write me a very short poem\
 about a happy carrot"""},  
] 
response = get_completion_from_messages(messages, temperature=1)
print(response)
```



```python
# length
messages =  [  
{'role':'system',
 'content':'All your responses must be \
one sentence long.'},    
{'role':'user',
 'content':'write me a story about a happy carrot'},  
] 
response = get_completion_from_messages(messages, temperature =1)
print(response)
```



```python
# combined
messages =  [  
{'role':'system',
 'content':"""You are an assistant who \
responds in the style of Dr Seuss. \
All your responses must be one sentence long."""},    
{'role':'user',
 'content':"""write me a story about a happy carrot"""},
] 
response = get_completion_from_messages(messages, 
                                        temperature =1)
print(response)
```



![image-20230602100646325](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20230602100646325.png)



## 统计 token 使用量

```python
def get_completion_and_token_count(messages, 
                                   model="gpt-3.5-turbo", 
                                   temperature=0, 
                                   max_tokens=500):
    
    response = openai.ChatCompletion.create(
        model=model,
        messages=messages,
        temperature=temperature, 
        max_tokens=max_tokens,
    )
    
    content = response.choices[0].message["content"]
    
    token_dict = {
'prompt_tokens':response['usage']['prompt_tokens'],
'completion_tokens':response['usage']['completion_tokens'],
'total_tokens':response['usage']['total_tokens'],
    }

    return content, token_dict
```


