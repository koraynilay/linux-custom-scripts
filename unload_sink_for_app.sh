#!/bin/sh
names=("$@")
sinks_file="/tmp/custom_app_sinks"
if [ -n "$1" ];then
	for n in "${names[@]}";do
		echo unloading $sink...
		sink="$(grep -F "$n" "$sinks_file" | cut -f1 -d';')"
		pactl unload-module "$sink"
		sed -i "s/^$sink;.*$//g" "$sinks_file"
	done
	echo done!
	notify-send -a "$0" "unloaded sinks $names"
else
	for sink in $(cut -f1 -d';' "$sinks_file");do
		echo unloading $sink...
		pactl unload-module "$sink"
		sed -i "s/^$sink;.*$//g" "$sinks_file"
	done
	echo removing $sinks_file...
	rm "$sinks_file"
	echo done!
	notify-send -a "$0" "unloaded custom sinks"
fi
