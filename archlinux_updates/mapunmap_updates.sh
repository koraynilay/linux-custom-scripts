#!/bin/sh
mapunmap(){
	echo mapunmap
	id=`comm -12 <(xdotool search -name "^archlinux_updates_script$" | sort) <(xdotool search -class "termite" | sort)`
	#id=`xdotool search --name "^archlinux_updates_script$"`
	#pid=`ps x | awk '/\/bin\/sh \/usr\/bin\/updates_dialog_text/ {print $1}'`
	if cat /tmp/archlinux_updates_script_hidden>/dev/null;then
		xdotool windowmap --sync $id
		rm /tmp/archlinux_updates_script_hidden
	else
		xdotool windowunmap --sync $id
		touch /tmp/archlinux_updates_script_hidden
	fi
}
if [ "$1" == "start" ];then
	dialog_id=`xdotool search --name "^archlinux_updates_script$"`
	if [ -n "$dialog_id" ];then
		echo kill
		xdotool windowkill $dialog_id
	fi
	echo start
	nice -n 19 termite -t "archlinux_updates_script" -e updates_dialog_text 2>/dev/null &!
	rm /tmp/archlinux_updates_script_hidden
	sleep 1
	mapunmap
	exit 0
else
	mapunmap
fi
