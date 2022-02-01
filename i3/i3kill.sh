#!/bin/bash
winID=$(xdotool getactivewindow)
winClass=$(xprop -id $winID WM_CLASS)
winName=$(xprop -id $winID WM_NAME)
sig=$(echo $1 | sed -e 's/[^0-9]//g')
echo $sig
if [[ $sig -gt 0 ]];then
	kill -$sig $(xdotool getwindowpid $winID)
	exit $?
fi
kill_command="i3-msg "'['"id=$winID"']'" kill"
echo $kill_command
#kill_command="echo i3-msg '[id=$winID]' kill"
if [[ $winClass = *"Steam"* ]]; then
	xdotool windowunmap $winID
	exit $?
elif [[ $winName = *"archlinux_updates_script"* ]]; then
	xdotool windowunmap $winID
	touch /tmp/archlinux_updates_script_hidden
	exit $?
elif [[ $winName = *"Chrome"* ]]; then
	zenity --question && $kill_command
	exit $?
else
	$kill_command
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
