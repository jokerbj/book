#!/bin/bash
git config user.name "jokerbj"
git config user.email "849185108@qq.com"
git branch
cd _book
git init
git add .
git commit -m "Travis CI Auto Builder at `date +"%Y-%m-%d %H:%M"`"
git push --force --quiet "https://${GH_TOKEN}@${GH_REF}" master:master