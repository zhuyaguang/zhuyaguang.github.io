# 吴恩达-基于LangChain的大语言模型应用开发


<!--more-->

# 基于LangChain的大语言模型应用开发

* 视频教程地址

  https://learn.deeplearning.ai/langchain/lesson/1/introduction

* 熟肉地址

  https://www.youtube.com/watch?v=gUcYC0Iuw2g&list=PLiuLMb-dLdWIYYBF3k5JI_6Od593EIuEG&index=1

* Langchain 官方文档

  https://blog.langchain.dev/

* LangChain 中文入门教程

​		https://github.com/liaokongVFX/LangChain-Chinese-Getting-Started-Guide

* LangChain 保姆级别教程

  https://dev.to/mikeyoung44/a-plain-english-guide-to-reverse-engineering-the-twitter-algorithm-with-langchain-activeloop-and-deepinfra-47fh

## 一、介绍

Langchain 主要有下面五个主要部分：

模型、提示词、索引、链、代理。

![image-20230607100333897](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20230607100333897.png)



## 二、模型，提示和输出解析

 一般情况下，prompt 中有变量，我们是这样处理的

```python
customer_email = """
Arrr, I be fuming that me blender lid \
flew off and splattered me kitchen walls \
with smoothie! And to make matters worse,\
the warranty don't cover the cost of \
cleaning up me kitchen. I need yer help \
right now, matey!
"""

style = """American English \
in a calm and respectful tone
"""

prompt = f"""Translate the text \
that is delimited by triple backticks 
into a style that is {style}.
text: ```{customer_email}```
"""

print(prompt)
```

### Prompt template

```python
from langchain.prompts import PromptTemplate
prompt = PromptTemplate(
    input_variables=["product"],
    template="What is a good name for a company that makes {product}?",
)
print(prompt.format(product="colorful socks"))

from langchain.prompts import ChatPromptTemplate
template_string = """Translate the text \
that is delimited by triple backticks \
into a style that is {style}. \
text: ```{text}```
"""
prompt_template = ChatPromptTemplate.from_template(template_string)

customer_style = """American English \
in a calm and respectful tone
"""
customer_email = """
Arrr, I be fuming that me blender lid \
flew off and splattered me kitchen walls \
with smoothie! And to make matters worse, \
the warranty don't cover the cost of \
cleaning up me kitchen. I need yer help \
right now, matey!
"""
customer_messages = prompt_template.format_messages(
                    style=customer_style,
                    text=customer_email)

print(customer_messages[0])
customer_response = model(customer_messages)
print(customer_response.content)
```

###  提取信息 按照 Json 格式输出

```python


customer_review = """\
This leaf blower is pretty amazing.  It has four settings:\
candle blower, gentle breeze, windy city, and tornado. \
It arrived in two days, just in time for my wife's \
anniversary present. \
I think my wife liked it so much she was speechless. \
So far I've been the only one using it, and I've been \
using it every other morning to clear the leaves on our lawn. \
It's slightly more expensive than the other leaf blowers \
out there, but I think it's worth it for the extra features.
"""

review_template = """\
For the following text, extract the following information:

gift: Was the item purchased as a gift for someone else? \
Answer True if yes, False if not or unknown.

delivery_days: How many days did it take for the product \
to arrive? If this information is not found, output -1.

price_value: Extract any sentences about the value or price,\
and output them as a comma separated Python list.

Format the output as JSON with the following keys:
gift
delivery_days
price_value

text: {text}
"""

from langchain.prompts import ChatPromptTemplate

prompt_template = ChatPromptTemplate.from_template(review_template)
print(prompt_template)

messages = prompt_template.format_messages(text=customer_review)
response = model(messages)
```



### 解析 LLM 输出的字符串为 python 字典

```python

from langchain.output_parsers import ResponseSchema
from langchain.output_parsers import StructuredOutputParser

gift_schema = ResponseSchema(name="gift",
                             description="Was the item purchased\
                             as a gift for someone else? \
                             Answer True if yes,\
                             False if not or unknown.")
delivery_days_schema = ResponseSchema(name="delivery_days",
                                      description="How many days\
                                      did it take for the product\
                                      to arrive? If this \
                                      information is not found,\
                                      output -1.")
price_value_schema = ResponseSchema(name="price_value",
                                    description="Extract any\
                                    sentences about the value or \
                                    price, and output them as a \
                                    comma separated Python list.")

response_schemas = [gift_schema, 
                    delivery_days_schema,
                    price_value_schema]

output_parser = StructuredOutputParser.from_response_schemas(response_schemas)
format_instructions = output_parser.get_format_instructions()
print(format_instructions)
review_template_2 = """\
For the following text, extract the following information:

gift: Was the item purchased as a gift for someone else? \
Answer True if yes, False if not or unknown.

delivery_days: How many days did it take for the product\
to arrive? If this information is not found, output -1.

price_value: Extract any sentences about the value or price,\
and output them as a comma separated Python list.

text: {text}

{format_instructions}
"""

prompt = ChatPromptTemplate.from_template(template=review_template_2)

messages = prompt.format_messages(text=customer_review, 
                                format_instructions=format_instructions)

response = model(messages)

output_dict = output_parser.parse(response.content)
print(output_dict.get('delivery_days'))
```

## 三、记忆



```python
from langchain.chains import ConversationChain
from langchain.memory import ConversationBufferMemory
model.temperature = 0.0
memory = ConversationBufferMemory()
conversation = ConversationChain(
    llm=model, 
    memory = memory,
    verbose=True
)
r = conversation.predict(input="Hi, my name is Andrew")
print(r)
conversation.predict(input="What is 1+1?")
conversation.predict(input="What is my name?")

print(memory.buffer)

memory.load_memory_variables({})
```

### 定义一个 memory 存储内容

```python
memory = ConversationBufferMemory() 
memory.save_context({"input": "Hi"}, 
                    {"output": "What's up"})

print(memory.buffer)

memory.load_memory_variables({})

memory.save_context({"input": "Not much, just hanging"}, 
                    {"output": "Cool"})

memory.load_memory_variables({})

print(memory.buffer)
```

### 限制对话轮数的 memory

```python
from langchain.memory import ConversationBufferWindowMemory

memory = ConversationBufferWindowMemory(k=1)
conversation = ConversationChain(
    llm=model, 
    memory = memory,
    verbose=False
)
conversation.predict(input="Hi, my name is Andrew")
conversation.predict(input="What is 1+1?")
s = conversation.predict(input="What is my name?")
print(s)
```

### 限制token 的 memory

```python
from langchain.memory import ConversationTokenBufferMemory

memory = ConversationTokenBufferMemory(llm=model, max_token_limit=30)
memory.save_context({"input": "AI is what?!"},
                    {"output": "Amazing!"})
memory.save_context({"input": "Backpropagation is what?"},
                    {"output": "Beautiful!"})
memory.save_context({"input": "Chatbots are what?"}, 
                    {"output": "Charming!"})


print(memory.buffer)

```

### 根据 token 自动总结的 memory

```python
from langchain.memory import ConversationSummaryBufferMemory
# create a long string
schedule = "There is a meeting at 8am with your product team. \
You will need your powerpoint presentation prepared. \
9am-12pm have time to work on your LangChain \
project which will go quickly because Langchain is such a powerful tool. \
At Noon, lunch at the italian resturant with a customer who is driving \
from over an hour away to meet you to understand the latest in AI. \
Be sure to bring your laptop to show the latest LLM demo."

memory = ConversationSummaryBufferMemory(llm=model, max_token_limit=100)
memory.save_context({"input": "Hello"}, {"output": "What's up"})
memory.save_context({"input": "Not much, just hanging"},
                    {"output": "Cool"})
memory.save_context({"input": "What is on the schedule today?"}, 
                    {"output": f"{schedule}"})

conversation = ConversationChain(
    llm=model, 
    memory = memory,
    verbose=True
)
r = conversation.predict(input="What would be a good demo to show?")
print(r)
print(memory.buffer)
```

### 其他记忆类型

实体记忆、向量数据库、KV数据库、关系型数据库

![image-20230616143835012](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20230616143835012.png)



## 四、链

### LLMChian

```python
import pandas as pd
df = pd.read_csv('Data.csv')
df.head()

from langchain.prompts import ChatPromptTemplate
from langchain.chains import LLMChain

model.temperature = 0.9

prompt = ChatPromptTemplate.from_template(
    "What is the best name to describe \
    a company that makes {product}?"
)

chain = LLMChain(llm=model, prompt=prompt)

product = "Queen Size Sheet Set"
r = chain.run(product)
print(r)
```



### 简单顺序链

![image-20230616153021289](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20230616153021289.png)

```python
from langchain.chains import SimpleSequentialChain

# prompt template 1
first_prompt = ChatPromptTemplate.from_template(
    "What is the best name to describe \
    a company that makes {product}?"
)

# Chain 1
chain_one = LLMChain(llm=model, prompt=first_prompt)

# prompt template 2
second_prompt = ChatPromptTemplate.from_template(
    "Write a 20 words description for the following \
    company:{company_name}"
)
# chain 2
chain_two = LLMChain(llm=model, prompt=second_prompt)

overall_simple_chain = SimpleSequentialChain(chains=[chain_one, chain_two],
                                             verbose=True
                                            )
r = overall_simple_chain.run(product)
print(r)
```



### 复杂顺序链

![image-20230616153115083](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20230616153115083.png)

```python
from langchain.chains import SequentialChain
# prompt template 1: translate to english
first_prompt = ChatPromptTemplate.from_template(
    "Translate the following review to english:"
    "\n\n{Review}"
)
# chain 1: input= Review and output= English_Review
chain_one = LLMChain(llm=model, prompt=first_prompt, 
                     output_key="English_Review"
                    )

second_prompt = ChatPromptTemplate.from_template(
    "Can you summarize the following review in 1 sentence:"
    "\n\n{English_Review}"
)
# chain 2: input= English_Review and output= summary
chain_two = LLMChain(llm=model, prompt=second_prompt, 
                     output_key="summary"
                    )

# prompt template 3: translate to english
third_prompt = ChatPromptTemplate.from_template(
    "What language is the following review:\n\n{Review}"
)
# chain 3: input= Review and output= language
chain_three = LLMChain(llm=model, prompt=third_prompt,
                       output_key="language"
                      )

# prompt template 4: follow up message
fourth_prompt = ChatPromptTemplate.from_template(
    "Write a follow up response to the following "
    "summary in the specified language:"
    "\n\nSummary: {summary}\n\nLanguage: {language}"
)
# chain 4: input= summary, language and output= followup_message
chain_four = LLMChain(llm=model, prompt=fourth_prompt,
                      output_key="followup_message"
                     )

# overall_chain: input= Review 
# and output= English_Review,summary, followup_message
overall_chain = SequentialChain(
    chains=[chain_one, chain_two, chain_three, chain_four],
    input_variables=["Review"],
    output_variables=["English_Review", "summary","followup_message"],
    verbose=True
)

review = "非常好吃，强烈推荐"
overall_chain(review)
```





### 路由链

![image-20230616153204891](https://zhuyaguang-1308110266.cos.ap-shanghai.myqcloud.com/img/image-20230616153204891.png)





````python
physics_template = """You are a very smart physics professor. \
You are great at answering questions about physics in a concise\
and easy to understand manner. \
When you don't know the answer to a question you admit\
that you don't know.

Here is a question:
{input}"""


math_template = """You are a very good mathematician. \
You are great at answering math questions. \
You are so good because you are able to break down \
hard problems into their component parts, 
answer the component parts, and then put them together\
to answer the broader question.

Here is a question:
{input}"""

history_template = """You are a very good historian. \
You have an excellent knowledge of and understanding of people,\
events and contexts from a range of historical periods. \
You have the ability to think, reflect, debate, discuss and \
evaluate the past. You have a respect for historical evidence\
and the ability to make use of it to support your explanations \
and judgements.

Here is a question:
{input}"""


computerscience_template = """ You are a successful computer scientist.\
You have a passion for creativity, collaboration,\
forward-thinking, confidence, strong problem-solving capabilities,\
understanding of theories and algorithms, and excellent communication \
skills. You are great at answering coding questions. \
You are so good because you know how to solve a problem by \
describing the solution in imperative steps \
that a machine can easily interpret and you know how to \
choose a solution that has a good balance between \
time complexity and space complexity. 

Here is a question:
{input}"""

prompt_infos = [
    {
        "name": "physics", 
        "description": "Good for answering questions about physics", 
        "prompt_template": physics_template
    },
    {
        "name": "math", 
        "description": "Good for answering math questions", 
        "prompt_template": math_template
    },
    {
        "name": "History", 
        "description": "Good for answering history questions", 
        "prompt_template": history_template
    },
    {
        "name": "computer science", 
        "description": "Good for answering computer science questions", 
        "prompt_template": computerscience_template
    }
]

from langchain.chains.router import MultiPromptChain
from langchain.chains.router.llm_router import LLMRouterChain,RouterOutputParser
from langchain.prompts import PromptTemplate


destination_chains = {}
for p_info in prompt_infos:
    name = p_info["name"]
    prompt_template = p_info["prompt_template"]
    prompt = ChatPromptTemplate.from_template(template=prompt_template)
    chain = LLMChain(llm=model, prompt=prompt)
    destination_chains[name] = chain  
    
destinations = [f"{p['name']}: {p['description']}" for p in prompt_infos]
destinations_str = "\n".join(destinations)

default_prompt = ChatPromptTemplate.from_template("{input}")
default_chain = LLMChain(llm=model, prompt=default_prompt)

MULTI_PROMPT_ROUTER_TEMPLATE = """Given a raw text input to a \
language model select the model prompt best suited for the input. \
You will be given the names of the available prompts and a \
description of what the prompt is best suited for. \
You may also revise the original input if you think that revising\
it will ultimately lead to a better response from the language model.

<< FORMATTING >>
Return a markdown code snippet with a JSON object formatted to look like:
```json
{{{{
    "destination": string \ name of the prompt to use or "DEFAULT"
    "next_inputs": string \ a potentially modified version of the original input
}}}}
```

REMEMBER: "destination" MUST be one of the candidate prompt \
names specified below OR it can be "DEFAULT" if the input is not\
well suited for any of the candidate prompts.
REMEMBER: "next_inputs" can just be the original input \
if you don't think any modifications are needed.

<< CANDIDATE PROMPTS >>
{destinations}

<< INPUT >>
{{input}}

<< OUTPUT (remember to include the ```json)>>"""

router_template = MULTI_PROMPT_ROUTER_TEMPLATE.format(
    destinations=destinations_str
)
router_prompt = PromptTemplate(
    template=router_template,
    input_variables=["input"],
    output_parser=RouterOutputParser(),
)

router_chain = LLMRouterChain.from_llm(model, router_prompt)

chain = MultiPromptChain(router_chain=router_chain, 
                         destination_chains=destination_chains, 
                         default_chain=default_chain, verbose=True
                        )

r = chain.run("What is black body radiation?")
print(r)
````



## 五、基于文档的问答































## 六、评估







## 七、代理























```
我们这是一个合作演讲，我负责讲解应用的开发过程，我的搭档负责讲解应用的部署。

我们都知道云原生，随着大模型的横空出世，基于 LLM 的应用也催生出来了。我们正处在 AI native 应用开发的前夜。因此在本次演讲中我介绍一种 AI native 应用的框架 LangChain 。

首先我会介绍 什么是 LangChain。然后怎么利用 LangChain 写出一个 hello world 级别的应用。

接下来分别介绍 LangChain 中五种最重要的模块 Models Prompts Indexes Chains Agents。

每个模块我都会有一个简单的demo。

Models模块我会介绍 LangChain 如何与市面上主流的大模型接入的方法。

Prompts  模块我会讲解 prompts 的书写技巧和原则，prompts 工程师的必备技能。

Indexes 模块 我会介绍 LangChain 与向量数据库的关系，如何利用向量数据库来构建私人知识库。

Chains 模块 我会介绍 思维链 的概念，已经 如何将业务逻辑分解成 大模型理解的思维链。

Agents 模块 我会介绍 怎么讲多个复杂的功能封装成一个 agent，大模型如何和外部工具结合使用。

我的搭档负责讲我写好的应用，编写成 Docker 镜像，并发布在 k8s 环境上使用体验。
This is a collaborative speech where I am responsible for explaining the application development process, and my partner is responsible for explaining the deployment process of the application.

We all know about cloud-native computing. With the emergence of large models, LLM-based applications have also emerged. We are on the eve of AI native application development. Therefore, in this speech, I will introduce a LangChain framework for AI native applications.

Firstly, I will introduce what LangChain is and then how to use LangChain to write a "hello world" level application.

Next, I will introduce the five most important modules in LangChain: Models, Prompts, Indexes, Chains, and Agents.

For the Models module, I will explain how LangChain integrates with mainstream large models on the market.

For the Prompts module, I will explain the writing skills and principles of prompts, which are essential skills for prompt engineers.

For the Indexes module, I will introduce the relationship between LangChain and vector databases and how to use vector databases to build private knowledge bases.

For the Chains module, I will explain the concept of thinking chains and how to break down business logic into thinking chains that large models can understand.

For the Agents module, I will explain how to encapsulate multiple complex functions into one agent and how large models can be used in conjunction with external tools.

My partner will be responsible for discussing the Docker image creation process for the application I have written and publishing it for use in a k8s environment.
```


