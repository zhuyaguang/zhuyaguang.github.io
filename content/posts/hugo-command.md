---
title: "Hugo Command"
date: 2022-04-10T08:41:30+08:00
draft: false
---

```shell
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/zhuyaguang/.zprofile

eval "$(/opt/homebrew/bin/brew shellenv)"

hugo new posts/hugo-command.md

hugo server -D

hugo --destination ./docs --buildDrafts --cleanDestinationDir 
```

