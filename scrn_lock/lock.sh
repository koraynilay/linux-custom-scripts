#!/bin/sh
#light_pic="$HOME/android_walls/new_linkin_fade_lock.png"
# dark_pic="$HOME/android_walls/new_linkin_fade_lock.png"
#light_pic="$HOME/android_walls/new.png"
#dark_pic="$HOME/android_walls/new.png"

#home="/home/koraynilay"
light_pic="$HOME/Pictures/wallpapers/sweet/landscape_sweet_light_blur.png"
dark_pic="$HOME/Pictures/wallpapers/sweet/landscape_sweet_dark_blur.png"
#light_pic="$home/Pictures/wallpapers/wave/landscape_wave_blur.png"
#dark_pic="$home/Pictures/wallpapers/wave/landscape_wave_4_blur.png"
font='Tw Cen MT'
if [ `date +%H` -lt 20 -a `date +%H` -ge 8 ];then
	pic=$light_pic
else
	pic=$dark_pic
fi
i3lock -n -k \
	-i "$pic" \
	-C \
	-c 000000 \
	\
	--timepos='x+30:h-200' \
	--timesize='100' \
	--timecolor=ffffffff \
	--time-align 1 \
	--time-font="$font" \
	--timestr='%k %M %S' \
	\
	--datepos='x+30:h-125' \
	--datesize='40' \
	--datecolor=ffffffff \
	--date-align 1 \
	--date-font="$font" \
	--datestr='%A %_d %B %Y' \
	\
	--insidevercolor=00000000 \
	--insidewrongcolor=ff000000 \
	--insidecolor=00000000 \
	\
	--pass-media-keys \
	--pass-screen-keys \
	\
	--indpos='x+1870:h-50' \
	--keyhlcolor=ffffffff \
	--bshlcolor=ff0000ff \
	--separatorcolor=00000000 \
	--radius=30 \
	--linecolor=ff000050 \
	--ringcolor=ff000000 \
	--ringvercolor=00000050 \
	--ringwrongcolor=ff000050 \
	--verifcolor=ffffffff \
	--wrongcolor=ff0000ff \
	--veriftext="." \
	--wrongtext="." \
	--noinputtext="" \
	--locktext="" \
	--lockfailedtext="" \
	--layout-font="$font" \
	--verif-font="$font" \
	--wrong-font="$font" #\
#	--debug	2> $HOME/i3lock.log
xset -dpms

#	--timestr='%l %M %S %p' \

#	\
#	--greetersize='30' \
#	--greeterpos='x+30:h-30' \
#	--greetercolor=ffffffff \
#	--greeter-align 1 \
#	--greeter-font="$font" \
#	--greetertext='Type your password...' \

#	\
#	--keylayout 0 \
#	--layoutcolor=ffffffff \
#	--layout-align 1 \
#	--layoutsize='20' \

#font='Anonymous Pro'
#font='Product Sans'
#font='Cascadia Code'
#font='IBM 3270'

#convert landscape_wave_4_blur.png -resize $(xdpyinfo | grep dimensions | sed -r 's/^[^0-9]*([0-9]+x[0-9]+).*$/\1/') RGB:- | i3lock --raw $(xdpyinfo | grep dimensions | sed -r 's/^[^0-9]*([0-9]+x[0-9]+).*$/\1/'):rgb --image /dev/stdin
