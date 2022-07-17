#!/bin/bash
kill_command() {
	if ! [ "$XDG_SESSION_TYPE" = "wayland" ];then
		i3-msg '['"id=$winID"']' kill
	else
		swaymsg '['"id=$winID"']' kill
	fi
}
kill_normal() {
	if ! [ "$XDG_SESSION_TYPE" = "wayland" ];then
		i3-msg kill
	else
		swaymsg kill
	fi
}
#kill_command="echo i3-msg '[id=$winID]' kill"

winID=$(xdotool getactivewindow)
if [ -z $winID ];then
	kill_normal
fi
winClass=$(xprop -id $winID WM_CLASS)
winName=$(xprop -id $winID WM_NAME)
sig=$(echo $1 | sed -e 's/[^0-9]//g')
echo $sig
if [[ $sig -gt 0 ]];then
	kill -$sig $(xdotool getwindowpid $winID)
	exit $?
fi
if [[ $winClass = *"Steam"* ]]; then
	if [ $sig -eq 9 ];then
		kill_command $winID
	else
		xdotool windowunmap $winID
	fi
	exit $?
elif [[ $winName = *"archlinux_updates_script"* ]]; then
	xdotool windowunmap $winID
	touch /tmp/archlinux_updates_script_hidden
	exit $?
elif [[ $winName = *"Chrome"* ]]; then
	zenity --question && kill_command $winID
	exit $?
else
	kill_command $winID
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
