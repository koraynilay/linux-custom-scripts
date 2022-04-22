#!/bin/sh
names=($@)
sinks_file="/tmp/custom_app_sinks"
if [ -n $1 ];then
	for nn in ${names[@]};do
		n="$nn"
		sink="$(grep -F $n $sinks_file | cut -f1 -d';')"
		pactl unload-module "$sink"
		sed -i "s/^$sink;.*$//g" $sinks_file
	done
else
	for sink in $(cut -f1 -d';' $sinks_file);do
		echo $sink
		pactl unload-module "$sink"
		sed -i "s/^$sink;.*$//g" $sinks_file
	done
	rm $sinks_file
fi
