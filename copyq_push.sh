#!/bin/sh
folder="/I/Raccolte/linux/koraynilay/copyq_backup"
cd "$folder"
git status
git add -A
git status
git commit -m "$(date +%Y-%m-%d_%H-%M-%S)"
git push
