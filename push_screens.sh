#!/bin/sh
cd /home/koraynilay/Pictures/screens
git add *
git commit -m "$(date +%Y-%m-%d_%H-%M-%S)"
git push
