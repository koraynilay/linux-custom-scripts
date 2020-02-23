#!/bin/sh
if cat /tmp/polybar_hidden>/dev/null;then
#	xdo show -N Polybar
#	xdo show -a polybar-bottom_DVI-D-0
#	xdo show -a Polybar\ tray\ window
	rm /tmp/polybar_hidden
else
#	xdo hide -N Polybar
#	xdo hide -a polybar-bottom_DVI-D-0
#	xdo hide -a Polybar\ tray\ window
	touch /tmp/polybar_hidden
fi
