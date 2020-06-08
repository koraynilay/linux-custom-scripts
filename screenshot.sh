#!/bin/sh
#slop_opts="-l -c 0.2,0,0.15,0.3 -b 1.5 -k -D"
case $1 in
	shot)
		maim "$HOME/Pictures/screens/$(date +%d-%m-%Y_%H-%M-%S).png" \
		&& dunstify -a maim "screenshot in ~/Pictures/screens"
	;;
	shos)
		maim \ 
			-s -l -k -D \
			-c 0.2,0,0.15,0.3 \
			-b 1.5 \
			"$HOME/Pictures/screens/$(date +%d-%m-%Y_%H-%M-%S).png" \
		&& dunstify -a maim "screenshot in ~/Pictures/screens"
	;;
	cast)
		slop=$(slop -l -c "0.2,0,0.15,0.3" -b 1.5 -k -D -f "%x %y %w %h %g %i") || exit 1
		read -r X Y W H G ID < <(echo $slop)
		recordmydesktop \
			-fps 60 \
			-freq 44100 \
			--no-wm-check \
			-device pulse \
			--stop-shortcut Control+Delete \
			--pause-shortcut Control+Insert \
			--on-the-fly-encoding \
			-o "$HOME/Videos/screencasts/$(date +%d-%m-%Y_%H-%M-%S).ogv" \
			&& dunstify -a recordmydesktop 'video saved in ~/Videos/screencasts'
	;;
esac
