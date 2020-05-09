#!/bin/sh
if [ "$1" == "start" ];then
	dialog_id=`xdotool search --name "^archlinux_updates_script$"`
	if [ -n "$dialog_id" ];then
		echo kill
		xdotool windowkill $dialog_id
	fi
	echo start
	termite -t "archlinux_updates_script" -e updates_dialog_text 2>/dev/null &!
	rm /tmp/archlinux_updates_script_hidden
	sleep 0.2
	mapunmap_updates.sh
	exit 0
else
	echo mapunmap
	id=`xdotool search --name "^archlinux_updates_script$"`
	pid=`ps x | awk '/\/bin\/sh \/usr\/bin\/updates_dialog_text/ {print $1}'`
	if cat /tmp/archlinux_updates_script_hidden>/dev/null;then
		xdotool windowmap $id
		rm /tmp/archlinux_updates_script_hidden
	else
		xdotool windowunmap $id
		touch /tmp/archlinux_updates_script_hidden
	fi
fi
