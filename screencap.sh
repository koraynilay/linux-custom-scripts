#!/bin/bash
slop_opts="-l -c 0.2,0,0.15,0.3 -b 1.5 -k" # -D"
date=$(date +%d-%m-%Y_%H-%M-%S)
xclip_gopts=""
# -filter_complex and -map are from https://trac.ffmpeg.org/wiki/AudioChannelManipulation (Section: Merged audio channel)
ffmepg_opts=" 	-hwaccel_output_format cuda \
		-f x11grab -i $DISPLAY size_to_replace \
		-f pulse -i 2 \
		-f pulse -i 1 \
		-filter_complex '[1:a][2:a] amerge=inputs=2,pan=stereo|c0<c0+c2|c1<c1+c3[a]' \
		-map 0 -map '[a]' -map 1 -map 2 \
		-c:v h264_nvenc -r:v 60 -b:v 10m -crf 0 \
		-c:a mp3 -r:a 44100 -b:a 320k \
		-preset fast"
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
		ffmpeg ${ffmepg_opts} \
			-o $filename \
			&& dunstify -a ffmpeg "video is $filename" \
			&& xclip $xclip_gopts -t video/ogg -selection clipboard "$filename"
	;;
	casts)
		slop=$(slop $slop_opts -f "%x %y %w %h %g %i") || exit 1 #[1]
		filename="$HOME/Videos/screencasts/${date}_select.ogv"
		read -r X Y W H G ID < <(echo $slop) #[1]
		echo $X $Y $W $H $G $ID
		ffmpeg $ffmepg_opts \
			-x $X \
			-y $Y \
			--width $W \
			--height $H \
			-o $filename \
			&& dunstify -a recordmydesktop "video is $filename" \
			&& xclip $xclip_gopts -t video/ogg -selection clipboard "$filename"
			#--windowid $ID \ #for recordmydesktop
	;;
	*)printf "Usage: $0 [shot|shots|cast|casts]\n";exit 1;;
	#*)printf "Usage: $0 [shot(s)|cast(s)]\n";exit 1;;
esac

#[1]: from https://github.com/naelstrof/slop/blob/master/README.md#practical-applications
