#!/bin/bash
slop_opts="-l -c 0.2,0,0.15,0.3 -b 1.5 -k" # -D"
date=$(date +%d-%m-%Y_%H-%M-%S)
recdesk_multi_opt="	-fps 60 \
			-freq 44100 \
			--no-wm-check \
			-device pulse \
			--stop-shortcut Control+Delete \
			--pause-shortcut Control+Insert \
			--on-the-fly-encoding"
case $1 in
	shot)
		maim "$HOME/Pictures/screens/${date}.png" \
		&& dunstify -a maim "screenshot in ~/Pictures/screens"
	;;
	shots)
		maim -s $slop_opts \
		"$HOME/Pictures/screens/${date}.png" \
		&& dunstify -a maim "screenshot in ~/Pictures/screens"
	;;
	cast)
		recordmydesktop $recdesk_multi_opt \
			-o "$HOME/Videos/screencasts/${date}.ogv" \
			&& dunstify -a recordmydesktop 'video saved in ~/Videos/screencasts'
	;;
	casts)
		slop=$(slop $slop_opts -f "%x %y %w %h %g %i") || exit 1 #[1]
		read -r X Y W H G ID < <(echo $slop) #[1]
		echo $X $Y $W $H $G $ID
		recordmydesktop \
			-x $X \
			-y $Y \
			--width $W \
			--height $H \
			$recdesk_multi_opt \
			-o "$HOME/Videos/screencasts/$(date +%d-%m-%Y_%H-%M-%S)_select.ogv" \
			&& dunstify -a recordmydesktop 'video saved in ~/Videos/screencasts'
			#--windowid $ID \ #for recordmydesktop
	;;
	*)printf "Usage: $0 [shot|shots|cast|casts]\n";exit 1;;
	#*)printf "Usage: $0 [shot(s)|cast(s)]\n";exit 1;;
esac

#[1]: from https://github.com/naelstrof/slop/blob/master/README.md#practical-applications
