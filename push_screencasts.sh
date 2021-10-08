#!/bin/sh
cd /home/koraynilay/Videos/screencasts
git add *
git commit -m "$(date +%Y-%m-%d_%H-%M-%S)"
git push
