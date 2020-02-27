#!/bin/sh
id=`xdotool search --name "^archlinux_updates_script$"`
pid=`ps x | awk '/\/bin\/sh \/usr\/bin\/updates_dialog_text/ {print $1}'`
[[ -z $id ]] && updates_dialog &!
if cat /tmp/archlinux_updates_script_hidden>/dev/null;then
	xdotool windowmap $id
	kill -USR1 $pid
	rm /tmp/archlinux_updates_script_hidden
else
	xdotool windowunmap $id
	touch /tmp/archlinux_updates_script_hidden
fi
