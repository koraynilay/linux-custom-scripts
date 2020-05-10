#!/bin/sh
case $1 in
	light)feh --bg-fill ~/Pictures/wallpapers/wave/landscape_wave.png;;
	dark)feh --bg-fill ~/Pictures/wallpapers/wave/landscape_wave_4.png;;
	*)printf "Usage: $0 [light|dark]\n";exit 1;;
esac
