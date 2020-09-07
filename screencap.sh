#!/bin/bash
lastfile="$HOME/.screencapsh"
lockfile="$HOME/.screencapsh.lck"
slop_opts="-l -c 0.2,0,0.15,0.3 -b 1.5 -k" # -D"
date=$(date +%d-%m-%Y_%H-%M-%S)
full_res=$(xrandr -q | awk '/\*/ {print $1}')
xclip_gopts=""
# -filter_complex and -map are from https://trac.ffmpeg.org/wiki/AudioChannelManipulation (Section: Merged audio channel)
ffmpeg_opts="-hwaccel_output_format cuda "
ffmpeg_opts+="-f x11grab size_to_replace -i ${DISPLAY}offset_to_replace "
ffmpeg_opts+="-f pulse -i 2 -ac 2 "
ffmpeg_opts+="-f pulse -i 1 -ac 1 "
ffmpeg_opts+="-filter_complex [1:a][2:a]amerge=inputs=2,pan=stereo|c0<c0+c2|c1<c1+c3[a] " #...2:a]amer... not really fixed, just a workaround ("no such filter" error) (instead of ...2:a] amer...)
ffmpeg_opts+="-map 0 -map [a] -map 1 -map 2 "
ffmpeg_opts+="-c:v h264_nvenc -r:v 60 -b:v 10m -crf 0 "
ffmpeg_opts+="-c:a mp3 -r:a 44100 -b:a 320k "
ffmpeg_opts+="-preset fast "
case $1 in
	shot)
		filename="$HOME/Pictures/screens/${date}.png"
		maim $filename \
			&& dunstify -a maim "screenshot is $filename" \
			&& xclip $xclip_gopts -t image/png -selection clipboard "$filename"
	;;
	shots)
		filename="$HOME/Pictures/screens/${date}.png"
		maim -s $slop_opts $filename \
			&& dunstify -a maim "screenshot is $filename" \
			&& xclip $xclip_gopts -t image/png -selection clipboard "$filename"
	;;
	cast)
		filename="$HOME/Videos/screencasts/${date}.mkv"
		ffmpeg_opts=${ffmpeg_opts/size_to_replace/-s $full_res}
		ffmpeg_opts=${ffmpeg_opts/offset_to_replace/}
		echo "$filename" > "$lastfile"
		dunstify -a screencap.sh "rec started" -t 200
		ffmpeg $ffmpeg_opts $filename  \
			; dunstify -a ffmpeg "screencast is $filename" \
			&& xclip $xclip_gopts -t video/ogg -selection clipboard "$filename"
	;;
	casts)
		slop=$(slop $slop_opts -f "%x %y %w %h %g %i") || exit 1 #[1]
		filename="$HOME/Videos/screencasts/${date}_select.mkv"
		read -r X Y W H G ID < <(echo $slop) #[1]
		#echo $X $Y $W $H $G $ID
		ffmpeg_opts=${ffmpeg_opts/size_to_replace/-s ${W}x${H}}
		ffmpeg_opts=${ffmpeg_opts/offset_to_replace/+$X,$Y}
		dunstify -a screencap.sh "rec started" -t 200
		ffmpeg $ffmpeg_opts $filename \
			; dunstify -a ffmpeg "screencast is $filename" \
			&& xclip $xclip_gopts -t video/ogg -selection clipboard "$filename"
			#--windowid $ID \ #for recordmydesktop
	;;
	stop_rec)
		killall -INT ffmpeg # or -2 code
		rm "$lastfile"
	;;
	pause_rec)
		killall -STOP ffmpeg && dunstify -a screencap.sh "rec paused" -t 1000  # or -19 code 
	;;
	resume_rec)
		killall -CONT ffmpeg && dunstify -a screencap.sh "rec resumed" -t 1000 # or -18 code
	;;
	toggle_rec)
		pgrep -P $(pgrep -f "$(basename $0).*cast.*") ffmpeg
		pgrep -P $(pgrep -f "$(basename /home/koraynilay/linux-custom-scripts/screencap.sh).*cast.*") ffmpeg
		exit
		if [ -z "$(pgrep -P $(pgrep $(basename $0)) ffmpeg)" ];then # if both are running
			killall -INT ffmpeg
			cp -vf "$lastfile" "$lockfile"
			rm "$lastfile"
		else
			if [ -s "$lockfile" ];then
				content_lock="$(cat "$lockfile")"
				fnl=${content_lock%.mkv}
				filename="${fnl}.tmp_to_concat.mkv"
				ffmpeg_opts=${ffmpeg_opts/size_to_replace/-s $full_res}
				ffmpeg_opts=${ffmpeg_opts/offset_to_replace/}
				dunstify -a screencap.sh "rec started" -t 200
				ffmpeg $ffmpeg_opts $filename  \
					; dunstify -a ffmpeg "screencast is $filename" \
					&& xclip $xclip_gopts -t video/ogg -selection clipboard "$filename"
				out_temp="${fnl}_concat.mkv"
				ffmpeg -f concat -safe 0 -i <(echo -e "$content_lock\n$filename") -c copy "$out_temp"
				mv -vi "$out_temp" "$content_lock"
				rm "$lockfile"
			fi
		fi
	;;
	*)echo -ne "Usage: $0 [shot|shots|cast|casts|stop_rec|pause_rec|resume_rec|toggle_rec]\n";exit 1;;
	#*)printf "Usage: $0 [shot(s)|cast(s)]\n";exit 1;;
esac
exit $?

#[1]: from https://github.com/naelstrof/slop/blob/master/README.md#practical-applications
