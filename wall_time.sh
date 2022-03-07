#!/bin/sh
light_pic="$HOME/Pictures/wallpapers/sweet/landscape_sweet_light.png"
dark_pic="$HOME/Pictures/wallpapers/sweet/landscape_sweet_dark.png"
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
	if   [ "$1" == "light" ];then
		pic=$light_pic
	elif [ "$1" == "dark"  ];then
		pic=$dark_pic
	elif [ "$1" == "auto"  ];then
		if [ `date +%H` -lt $hs -a `date +%H` -ge $hm ];then
			pic=$light_pic
		else
			pic=$dark_pic
		fi
	fi

	if ! [ "$XDG_SESSION_TYPE" = "wayland" ];then
		feh --bg-fill "$pic"
	else
		swaymsg output '*' bg "$pic" fill
	fi
}

case $1 in
	l|light)swi light;;
	d|dark)swi dark;;
	a|auto)swi auto;;
	*)printf "Usage: $0 [light|dark|auto]\n";exit 1;;
esac
