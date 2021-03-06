#!/bin/sh
font='Tw Cen MT'
i3lock --pass-media-keys -n -k \
	-i "~/Pictures/wallpapers/landscape_2_dark_lock.png" \
	\
	--timepos='x+30:h-200' \
	--timesize='140' \
	--timecolor=ffffffff \
	--time-align 1 \
	--time-font="$font" \
	--timestr='%H %M' \
	\
	--datepos='x+30:h-125' \
	--datesize='70' \
	--datecolor=ffffffff \
	--date-align 1 \
	--date-font="$font" \
	--datestr='%S' \
	\
	--insidevercolor=00000000 \
	--insidewrongcolor=ff000000 \
	--insidecolor=00000000 \
	\
	--indpos='x+1980:h-50' \
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
	--wrong-font="$font"

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
