# 吴恩达-使用ChatGPT API构建系统-笔记




# 使用ChatGPT API构建系统





翻转字符串得到的结果不对，因为大模型是根据 token 来处理下一个单词的，而不是 word。

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

