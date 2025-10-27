#!/bin/bash
sound="$(pactl get-default-sink).monitor"
mic="$(pactl get-default-source)"
ext="mp4"
time_sec=300
folder="/home/koraynilay/Videos/screencasts"
fps=60
quality="ultra"
mode="screen-direct" # screen only records 1 monitor, screen-direct all of them
recpidfile="/tmp/gpu-screen-recorder-recordpidfile"
case $1 in
	start)
		gpu-screen-recorder -w "$mode" -c "$ext" -f "$fps" -a "$sound" -a "$mic" -q "$quality" -r "$time_sec" -k h265 -cursor yes -o "$folder" &!
		;;
	record)
		gpu-screen-recorder -w "$mode" -c "$ext" -f "$fps" -a "$sound" -a "$mic" -q "$quality" -k h265 -cursor yes -o "$folder/$(date +%Y-%m-%d_%H-%M-%S).$ext" &!
		echo $! > "$recpidfile"
		;;
	stop-record)
		kill -SIGINT $(<"$recpidfile")
		;;
	save-replay)
		killall -SIGUSR1 gpu-screen-recorder
		if [ $? -ne 0 ]; then
			dunstify -a gpu-screen-recorder "not running" -u critical
		else
			dunstify -a gpu-screen-recorder "Replay saved in $folder"
		fi
		;;
	pause)
		killall -STOP gpu-screen-recorder
		;;
	cont)
		killall -CONT gpu-screen-recorder
		;;
esac
