#!/bin/sh
git status
git add .
git status
#sleep 1
git commit -m "$(date +%Y-%m-%d_%H:%M:%S) - lastncmfat port to zsh - for reorder_ost()"
#sleep 1
git push
notify-send -a GitHub "changes in $PWD pushed"
