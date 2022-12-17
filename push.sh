#!/bin/sh
git status
git add . -v
git status
#sleep 1
git commit -m "$(date +%Y-%m-%d_%H:%M:%S)"
#sleep 1
notify-send -a GitHub "pushing changes in $PWD..."
git push
if [ $? -eq 0 ];then
       notify-send -a GitHub "changes in $PWD pushed"
else
       notify-send -u critical -a GitHub "error in push of changes in $PWD"
fi
