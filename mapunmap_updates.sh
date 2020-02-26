#!/bin/sh
id=xdotool search --name "^archlinux_updates_script$"
if cat /tmp/archlinux_updates_script_hidden>/dev/null;then
	xdotool windowmap $id
	rm /tmp/archlinux_updates_script_hidden
else
	xdotool windowmap $id
	touch /tmp/archlinux_updates_script_hidden
fi
