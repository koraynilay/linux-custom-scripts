#!/bin/sh
light_pic="$HOME/Pictures/wallpapers/sweet/landscape_sweet_light.png"
dark_pic="$HOME/Pictures/wallpapers/sweet/landscape_sweet_dark.png"
swi(){
	if [ `date +%H` -lt 20 -a `date +%H` -gt 7 ];then
		feh --bg-fill $light_pic
	else
		feh --bg-fill $dark_pic
	fi
}

case $1 in
	l|light)feh --bg-fill $light_pic;;
	d|dark)feh --bg-fill $dark_pic;;
	a|auto)swi;;
	*)printf "Usage: $0 [light|dark|auto]\n";exit 1;;
esac
