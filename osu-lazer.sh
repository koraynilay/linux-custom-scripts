#!/bin/sh
#export SDL_VIDEO_X11_FORCE_EGL=true
# from https://github.com/ppy/osu/issues/11800#issuecomment-878649469
export COMPlus_GCGen0MaxBudget=600000
# from https://github.com/ppy/osu/issues/11800#issuecomment-786541035
export COMPlus_TieredCompilation=0
export COMPlus_TC_QuickJit=0
export COMPlus_TC_QuickJitForLoops=0

#LC_ALL=C osu-lazer 2>&1 > ~/osu_log.log
osu-lazer 2>&1 > ~/osu_log.log
cd /C/osu
./push.sh
