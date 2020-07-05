#!/bin/sh
swi(){
	if [ `date +%H` -lt 20 -a `date +%H` -gt 7 ];then
		feh --bg-fill ~/Pictures/wallpapers/wave/landscape_wave.png
	else
		feh --bg-fill ~/Pictures/wallpapers/wave/landscape_wave_4.png
	fi
}

case $1 in
	light)feh --bg-fill ~/Pictures/wallpapers/wave/landscape_wave.png;;
	dark)feh --bg-fill ~/Pictures/wallpapers/wave/landscape_wave_4.png;;
	auto)swi;;
	*)printf "Usage: $0 [light|dark|auto]\n";exit 1;;
esac
