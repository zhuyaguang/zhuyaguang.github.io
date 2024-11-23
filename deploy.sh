echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/zhuyaguang/.zprofile

eval "$(/opt/homebrew/bin/brew shellenv)"
hugo --destination ./docs --buildDrafts --cleanDestinationDir 
git add .
git commit -m "update $(date '+%Y-%m-%d %H:%M:%S')"
git push
