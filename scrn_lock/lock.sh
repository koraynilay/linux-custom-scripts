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
#echo $light_pic
#echo $dark_pic
font='Tw Cen MT'
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
if [ `date +%H` -lt $hs -a `date +%H` -ge $hm ];then
	pic=$light_pic
else
	pic=$dark_pic
fi
i3lock -n -k \
	-i "$pic" \
	-C \
	-c 000000 \
	\
	--time-pos='x+30:h-200' \
	--time-size='100' \
	--time-color=ffffffff \
	--time-align 1 \
	--time-font="$font" \
	--time-str='%k %M %S' \
	\
	--date-pos='x+30:h-125' \
	--date-size='40' \
	--date-color=ffffffff \
	--date-align 1 \
	--date-font="$font" \
	--date-str='%A %_d %B %Y' \
	\
	--insidever-color=00000000 \
	--insidewrong-color=ff000000 \
	--inside-color=00000000 \
	\
	--pass-media-keys \
	--pass-screen-keys \
	\
	--ind-pos='x+1870:h-50' \
	--keyhl-color=ffffffff \
	--bshl-color=ff0000ff \
	--separator-color=00000000 \
	--radius=30 \
	--line-color=ff000050 \
	--ring-color=ff000000 \
	--ringver-color=00000050 \
	--ringwrong-color=ff000050 \
	--verif-color=ffffffff \
	--wrong-color=ff0000ff \
	--verif-text="." \
	--wrong-text="." \
	--noinput-text="" \
	--lock-text="" \
	--lockfailed-text="" \
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
