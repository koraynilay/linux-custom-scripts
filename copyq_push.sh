#!/bin/sh
file="$HOME/.config/copyq/copyq_tab_JmNsaXBib2FyZA==.dat $HOME/.local/share/copyq"
folder="/Q/copyq_dat_file"
cd "$folder"
rsync --progress -xvaHAX --delete -c --cc xxh3 $file .
git status
git add -A
git status
git commit -m "$(date +%Y-%m-%d_%H-%M-%S)"
git push
