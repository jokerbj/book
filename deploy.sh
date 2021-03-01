#!/bin/bash
# GIT全局配置
git config user.name "jokerbj"
git config user.email "849185108@qq.com"
# 进入通过GITBOOK BUILD构建的BOOK目录，存放着目录结构，文章，插件
cd _book
# 初始化GIT
git init
# 添加所有文件
git add .
# 提交
git commit -m "Travis CI Auto Builder at `date +"%Y-%m-%d %H:%M"`"
git push --force --quiet "https://${GH_TOKEN}@${GH_REF}" master:master
