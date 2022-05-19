#!/bin/sh
#export SDL_VIDEO_X11_FORCE_EGL=true
osu-lazer 2>&1 > ~/osu_log.log
cd /C/osu
./push.sh
