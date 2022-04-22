#!/bin/sh
case $1 in
	on)  create_sink_for_app.sh "$(xdotool getactivewindow getwindowname)";;
	off) unload_sink_for_app.sh "$(xdotool getactivewindow getwindowname)";;
esac
