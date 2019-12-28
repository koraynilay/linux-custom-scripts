#!/bin/sh
git status
git add .
sleep 1
git commit -m "bck on $(date +%Y-%m-%d_%H:%M:%S)"
sleep 1
git push
notify-send -a GitHub "changes in $PWD pushed"
