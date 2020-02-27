#!/bin/sh
id=`xdotool search --name "^archlinux_updates_script$"`
[[ -z $id ]] && updates_dialog &!
if cat /tmp/archlinux_updates_script_hidden>/dev/null;then
	xdotool windowmap $id
	rm /tmp/archlinux_updates_script_hidden
else
	xdotool windowunmap $id
	touch /tmp/archlinux_updates_script_hidden
fi
