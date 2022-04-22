#!/bin/sh
names=("$@")
sinks_file="/tmp/custom_app_sinks"
common_sink_name="common_sink"
for n in "${names[@]}";do
	defsink="$(pactl get-default-sink)"
	echo loading sink for "$n"...
	common_sink="$(pactl load-module module-null-sink sink_name=$common_sink_name sink_properties=device.description=$common_sink_name)"
	sn="$(echo $n | md5sum | tr -d ' ' | tr -d '-')" #sn = sink name
	echo $sn
	sink="$(pactl load-module module-null-sink sink_name="$sn" sink_properties=device.description="$sn")"
	lp="$(pactl load-module module-loopback source="$sn.monitor" sink=$common_sink_name)" # lp = loopback
	pactl set-default-sink "$defsink"
	echo loaded sink $sink for "$n"...
	notify-send -a "$0" "added sink $sink named '$n'"
	printf "%d;" $sink >> "$sinks_file"
	printf "%s\n" "$n" >> "$sinks_file"
	printf "%d;" $common_sink >> "$sinks_file"
	printf "%s\n" "$n - common_sink" >> "$sinks_file"
	printf "%d;" $lp >> "$sinks_file"
	printf "%s\n" "$n - loopback" >> "$sinks_file"
	printf "\n" >> "$sinks_file"
done
