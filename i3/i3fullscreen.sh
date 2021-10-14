#!/bin/bash
winID=$(xdotool getactivewindow)
winClass=$(xprop -id $winID WM_CLASS)
winName=$(xprop -id $winID WM_NAME)
echo $sig
if [[ $winClass = *"Google-chrome"* ]]; then
	dunstify google
	#dunstify "$(xdotool key --window $winID F11 2>&1)"
	#xdotool key --window $winID F11
	xdotool getactivewindow key F11
	exit $?
else
	dunstify else
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
