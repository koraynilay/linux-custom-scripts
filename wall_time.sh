#!/bin/sh
light_pic="$HOME/Pictures/wallpapers/sweet/landscape_sweet_light.png"
dark_pic="$HOME/Pictures/wallpapers/sweet/landscape_sweet_dark.png"
if [ "$XDG_SESSION_TYPE" = "wayland" ];then
	bg_cmd=swaybg
else
	bg_cmd=feh
fi
if perl -e 'exit ((localtime)[8])' ; then
	#winter (DST off)
	#echo winter
	hs=18 #hour sera
	hm=7  #hour mattina
else
	#summer (DST on)
	#echo summer
	hs=20 #hour sera
	hm=8  #hour mattina
fi
swi(){
	if [ `date +%H` -lt $hs -a `date +%H` -gt $hm ];then
		$bg_cmd --bg-fill $light_pic
	else
		$bg_cmd --bg-fill $dark_pic
	fi
}

case $1 in
	l|light)$bg_cmd --bg-fill $light_pic;;
	d|dark)$bg_cmd --bg-fill $dark_pic;;
	a|auto)swi;;
	*)printf "Usage: $0 [light|dark|auto]\n";exit 1;;
esac
