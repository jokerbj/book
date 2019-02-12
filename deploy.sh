#!/bin/bash
git config user.name "jokerbj"
git config user.email "849185108@qq.com"
echo "1"
git branch
echo "2"
cd _book
git init
echo "3"
git add .
echo "4"
git commit -m "Travis CI Auto Builder at `date +"%Y-%m-%d %H:%M"`"
git push --force --quiet "https://${GH_TOKEN}@${GH_REF}" master:master