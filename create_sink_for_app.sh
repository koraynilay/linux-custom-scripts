#!/bin/sh
names=("$@")
sinks_file="/tmp/custom_app_sinks"
for n in "${names[@]}";do
	defsink="$(pactl get-default-sink)"
	echo loading sink for "$n"...
	sink="$(pactl load-module module-null-sink sink_name="$(echo $n | tr ' ' '_')" sink_properties=device.description="$(echo $n | tr ' ' '_')")"
	pactl set-default-sink "$defsink"
	echo loaded sink $sink for "$n"...
	notify-send -a "$0" "added sink $sink named '$n'"
	printf "%d;" $sink >> "$sinks_file"
	printf "%s\n" "$n" >> "$sinks_file"
done
