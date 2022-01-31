#!/bin/bash
winID=$(xdotool getactivewindow)
winClass=$(xprop -id $winID WM_CLASS)
winName=$(xprop -id $winID WM_NAME)
sig=$(echo $1 | sed -e 's/[^0-9]//g')
echo $sig
if [ $sig -gt 0 ];then
	kill -$sig $(xdotool getwindowpid $winID)
	exit $?
fi
if [[ $winClass = *"Steam"* ]]; then
	xdotool windowunmap $winID
	exit $?
elif [[ $winName = *"archlinux_updates_script"* ]]; then
	xdotool windowunmap $winID
	touch /tmp/archlinux_updates_script_hidden
	exit $?
elif [[ $winName = *"Chrome"* ]]; then
	zenity --question && i3-msg kill
	exit $?
else
	i3-msg kill
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
