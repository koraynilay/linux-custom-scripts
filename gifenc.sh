#!/bin/sh

palette="/tmp/palette.png"
filters="fps=24,scale=720:-1:flags=lanczos"

ffmpeg -v warning -i $1 -vf "$filters,palettegen=stats_mode=diff" -y $palette
ffmpeg -v warning -i $1 -i $palette -lavfi "$filters [x]; [x][1:v] paletteuse" -y $2

# from https://blog.pkh.me/p/21-high-quality-gif-with-ffmpeg.html
