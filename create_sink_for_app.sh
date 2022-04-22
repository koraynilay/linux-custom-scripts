#!/bin/sh
names=($@)
sinks_file="/tmp/custom_app_sinks"
for nn in ${names[@]};do
	n="$nn"
	defsink="$(pactl get-default-sink)"
	sink="$(pactl load-module module-null-sink sink_name=$n sink_properties=device.description=$n)"
	pactl set-default-sink $defsink
	notify-send -a "$0" "added sink '$n' with id:$sink"
	printf "%d;" $sink >> $sinks_file
	printf "%s\n"  $n >> $sinks_file
done
