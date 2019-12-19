#!/bin/sh
git status
git add .
sleep 1
git commit -m configs
sleep 1
git push
