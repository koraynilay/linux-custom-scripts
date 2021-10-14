#!/bin/bash
winID=$(xdotool getactivewindow)
winClass=$(xprop -id $winID WM_CLASS)
winName=$(xprop -id $winID WM_NAME)
echo $sig
if [[ $winClass = *"google-chrome"* ]]; then
	xdotool key F11
	exit $?
else
	i3-msg fullscreen toggle
	exit $?
fi



#winID=$(xdotool getactivewindow)
#winClass=$(xprop -id $winID WM_CLASS)
#winName=$(xprop -id $winID WM_NAME)
#if [[ $winClass = *"Steam"* ]]; then
#	xdotool windowunmap $(xdotool getactivewindow)
#	exit
#elif [[ $winName = *"archlinux_updates_script"* ]]; then
#	xdotool windowunmap $(xdotool getactivewindow)
#	touch /tmp/archlinux_updates_script_hidden
#	exit
#else
#	i3-msg kill
#	exit;
#fi
