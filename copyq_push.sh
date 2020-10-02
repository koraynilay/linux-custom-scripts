#!/bin/sh
file="$HOME/.config/copyq/copyq_tab_JmNsaXBib2FyZA==.dat"
folder="/I/Raccolte/linux/koraynilay/copyq_backup"
cd "$folder"
cp -v "$file" .
git status
git add -A
git status
git commit -m "$(date +%Y-%m-%d_%H-%M-%S)"
git push
