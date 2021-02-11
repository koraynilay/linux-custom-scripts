#!/bin/sh
SESSION_BUDDY_ICON_X=1650
SESSION_BUDDY_ICON_Y=73
SESSION_BUDDY_SAVE_X=1650
SESSION_BUDDY_SAVE_Y=220
xdotool mousemove $SESSION_BUDDY_ICON_X $SESSION_BUDDY_ICON_Y\
	click 1\
	mousemove restore\
	mousemove $SESSION_BUDDY_SAVE_X $SESSION_BUDDY_SAVE_Y\
	sleep 1.5\
	click 1\
	mousemove restore
#	key Ctrl+W
