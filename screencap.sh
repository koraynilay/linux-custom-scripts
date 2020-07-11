#!/bin/bash
slop_opts="-l -c 0.2,0,0.15,0.3 -b 1.5 -k" # -D"
date=$(date +%d-%m-%Y_%H-%M-%S)
xclip_gopts=""
recdesk_multi_opt="	--freq 44100 \
			--no-wm-check \
			--device pulse \
			--stop-shortcut Control+Delete \
			--pause-shortcut Control+Insert \
			--on-the-fly-encoding"
			# --fps 60 #not working, cause it speeds a lot up the video
case $1 in
	shot)
		filename="$HOME/Pictures/screens/${date}.png"
		maim $filename \
		&& dunstify -a maim "screenshot is $filename" \
		&& xclip $xclip_gopts -t image/png -selection clipboard "$filename"
	;;
	shots)
		filename="$HOME/Pictures/screens/${date}.png"
		maim -s $slop_opts \
		$filename \
		&& dunstify -a maim "screenshot is $filename" \
		&& xclip $xclip_gopts -t image/png -selection clipboard "$filename"
	;;
	cast)
		filename="$HOME/Videos/screencasts/${date}.ogv"
		recordmydesktop $recdesk_multi_opt \
			-o $filename \
			&& dunstify -a recordmydesktop "video is $filename" \
			&& xclip $xclip_gopts -t video/ogg -selection clipboard "$filename"
	;;
	casts)
		slop=$(slop $slop_opts -f "%x %y %w %h %g %i") || exit 1 #[1]
		filename="$HOME/Videos/screencasts/${date}_select.ogv"
		read -r X Y W H G ID < <(echo $slop) #[1]
		echo $X $Y $W $H $G $ID
		recordmydesktop \
			-x $X \
			-y $Y \
			--width $W \
			--height $H \
			$recdesk_multi_opt \
			-o $filename \
			&& dunstify -a recordmydesktop "video is $filename" \
			&& xclip $xclip_gopts -t video/ogg -selection clipboard "$filename"
			#--windowid $ID \ #for recordmydesktop
	;;
	*)printf "Usage: $0 [shot|shots|cast|casts]\n";exit 1;;
	#*)printf "Usage: $0 [shot(s)|cast(s)]\n";exit 1;;
esac

#[1]: from https://github.com/naelstrof/slop/blob/master/README.md#practical-applications
