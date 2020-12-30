#!/bin/bash 

# Ctrl	- Video Recording modifier
# Shift	- Selection modifier
# Alt	- Focused window modifier

lastfile="$HOME/.screencapsh"
lockfile="$HOME/.screencapsh.lck"

video_ext="mp4"
image_ext="png"

slop_opts="-l -c 0.2,0,0.15,0.3 -b 1.5 -k -n" # -D"
#date=$(date +%d-%m-%Y_%H-%M-%S)
date=$(date +%Y-%m-%d_%H-%M-%S)

full_res=$(xrandr -q | awk '/\*/ {print $1}')
primary_monitor_res=$(xrandr -q | awk '/\sconnected\sprimary/ {print $4}')
secondary_monitor_res=$(xrandr -q | awk '/\sconnected\s[^primary]/ {print $3}')
primary_monitor_res=${primary_monitor_res%[0-9]+x[0-9]+}
secondary_monitor_res=$(xrandr -q | awk '/\sconnected\s[^primary]/ {print $3}')
xclip_opts=""

#[3]
tmp_ifs=$IFS
IFS=$'\n'
eval $(xdotool getmouselocation --shell)
for i in $(xrandr -q | grep -Eo '[^ ]+\+[0-9]+\+[0-9]+' | sed 's/x\|+/ /g');do
	IFS=' '
	read -r w h ox oy < <(echo $i)
#	echo w:$w h:$h ox:$ox oy:$oy
#	echo X:$X Y:$Y
	if [[ $X -ge $ox && $X -lt $(($w+$ox)) && $Y -ge $oy && $Y -lt $(($h+$oy)) ]];then
#		echo ${w}x$h $DISPLAY+$ox,$oy
		size_to_replace="${w}x${h}"
		offset_to_replace="+$ox,$oy"
	fi
	IFS=$'\n'
done
IFS=$tmp_ifs
echo $size_to_replace $offset_to_replace
ffmpeg_opts_video="-hwaccel_output_format cuda "
ffmpeg_opts_video+="-f x11grab size_to_replace -i ${DISPLAY}offset_to_replace "
ffmpeg_opts_video+="-f pulse -i PulseEffects_apps.monitor -ac 2 " #pulseffects_apps # audio
ffmpeg_opts_video+="-f pulse -i PulseEffects_mic.monitor -ac 1 " #pulseffects_mic  # microphone
ffmpeg_opts_video+="-filter_complex [1:a][2:a]amerge=inputs=2,pan=stereo|c0<c0+c2|c1<c1+c3[a] " #[2]
ffmpeg_opts_video+="-map 0 -map [a] -map 1 -map 2 "
ffmpeg_opts_video+="-c:v h264_nvenc -r:v 60 -b:v 10m -crf 0 "
ffmpeg_opts_video+="-c:a mp3 -r:a 44100 -b:a 320k "
ffmpeg_opts_video+="-preset fast "

ffmpeg_opts_image="-f x11grab size_to_replace -i ${DISPLAY}offset_to_replace "
ffmpeg_opts_image+="-vframes 1 -pix_fmt rgba "
ffmpeg_opts_image+="-preset fast "

started_notif_time=200
finished_notif_time=10000
paused_notif_time=1000
resumed_notif_time=1000

case $1 in
	shot)
		filename="$HOME/Pictures/screens/${date}.${image_ext}"
		ffmpeg_opts_image=${ffmpeg_opts_image/size_to_replace/-s $size_to_replace}
		ffmpeg_opts_image=${ffmpeg_opts_image/offset_to_replace/$offset_to_replace}
		ffmpeg $ffmpeg_opts_image $filename \
			&& dunstify -a ffmpeg "screenshot is $filename" -t $finished_notif_time -I "$filename" \
			&& xclip $xclip_opts -t image/png -selection clipboard "$filename"
			#&& echo $filename | xclip -selection clipboard
	;;
	shots)
		slop=$(slop $slop_opts -f "%x %y %w %h %g %i") || exit 1 #[1]
		filename="$HOME/Pictures/screens/${date}.${image_ext}"
		read -r X Y W H G ID < <(echo $slop) #[1]
		ffmpeg_opts_image=${ffmpeg_opts_image/size_to_replace/-s ${W}x${H}}
		ffmpeg_opts_image=${ffmpeg_opts_image/offset_to_replace/+${X},${Y}}
		ffmpeg $ffmpeg_opts_image $filename \
			&& dunstify -a ffmpeg "screenshot is $filename" -t $finished_notif_time -I "$filename" \
			&& xclip $xclip_opts -t image/png -selection clipboard "$filename"
	;;
	shotw)
		slop=$(xwininfo -id $(xdotool getactivewindow) | awk 'BEGIN{res=""} /Absolute upper|Width|Height/ {res=res$NF" "}END{print res}') || exit 1 #[1]
		# slop=$(xwininfo -id $(xdotool getactivewindow) | grep -oP --no-ignore-case '(?<=Absolute.{13}:|Width:|Height:)\s+[0-9]+' | sed 's/\s*//g') || exit 1 #[1]
		filename="$HOME/Pictures/screens/${date}.${image_ext}"
		read -r X Y W H < <(echo $slop) #[1]
		ffmpeg_opts_image=${ffmpeg_opts_image/size_to_replace/-s ${W}x${H}}
		ffmpeg_opts_image=${ffmpeg_opts_image/offset_to_replace/+${X},${Y}}
		ffmpeg $ffmpeg_opts_image $filename \
			&& dunstify -a ffmpeg "screenshot is $filename" -t $finished_notif_time -I "$filename" \
			&& xclip $xclip_opts -t image/png -selection clipboard "$filename"
	;;
	cast)
		filename="$HOME/Videos/screencasts/${date}.${video_ext}"
		#filename="$HOME/ciciciaoicoai.mp4"
		ffmpeg_opts_video=${ffmpeg_opts_video/size_to_replace/-s $size_to_replace}
		ffmpeg_opts_video=${ffmpeg_opts_video/offset_to_replace/$offset_to_replace}
		echo "$filename" > "$lastfile"

		dunstify -a screencap.sh "rec started" -t $started_notif_time
		ffmpeg $ffmpeg_opts_video $filename
		ffmpeg_exit_code=$?
		echo $ffmpeg_exit_code
		if [ $ffmpeg_exit_code -eq 255 ] || [ $ffmpeg_exit_code -eq 0 ];then
			dunstify -a ffmpeg "screencast is $filename" -t $finished_notif_time
			xclip $xclip_opts -t video/ogg -selection clipboard "$filename"
		fi
		#else #this is cleaner, but if the exit codes change then the file would be removed
		#	rm "$filename"
		#fi
	;;
	casts)
		slop=$(slop $slop_opts -f "%x %y %w %h %g %i") || exit 1 #[1]
		filename="$HOME/Videos/screencasts/${date}_select.${video_ext}"
		read -r X Y W H G ID < <(echo $slop) #[1]
		ffmpeg_opts_video=${ffmpeg_opts_video/size_to_replace/-s ${W}x${H}}
		ffmpeg_opts_video=${ffmpeg_opts_video/offset_to_replace/+${X},${Y}}
		echo -e "$filename\n$X\n$Y\n$W\n$H" > "$lastfile"

		dunstify -a screencap.sh "rec started" -t $started_notif_time
		ffmpeg $ffmpeg_opts_video $filename
		ffmpeg_exit_code=$?
		echo $ffmpeg_exit_code
		if [ $ffmpeg_exit_code -eq 255 ] || [ $ffmpeg_exit_code -eq 0 ];then
			dunstify -a ffmpeg "screencast is $filename" -t $finished_notif_time
			xclip $xclip_opts -t video/ogg -selection clipboard "$filename"
		fi
		#else #this is cleaner, but if the exit codes change then the file would be removed
		#	rm "$filename"
		#fi
	;;
	castw)
		slop=$(xwininfo -id $(xdotool getactivewindow) | awk 'BEGIN{res=""} /Absolute upper|Width|Height/ {res=res$NF" "}END{print res}') || exit 1 #[1]
		filename="$HOME/Videos/screencasts/${date}_select.${video_ext}"
		read -r X Y W H < <(echo $slop) #[1]
		ffmpeg_opts_video=${ffmpeg_opts_video/size_to_replace/-s ${W}x${H}}
		ffmpeg_opts_video=${ffmpeg_opts_video/offset_to_replace/+${X},${Y}}
		echo -e "$filename\n$X\n$Y\n$W\n$H" > "$lastfile"

		dunstify -a screencap.sh "rec started" -t $started_notif_time
		ffmpeg $ffmpeg_opts_video $filename
		ffmpeg_exit_code=$?
		echo $ffmpeg_exit_code
		if [ $ffmpeg_exit_code -eq 255 ] || [ $ffmpeg_exit_code -eq 0 ];then
			dunstify -a ffmpeg "screencast is $filename" -t $finished_notif_time
			xclip $xclip_opts -t video/ogg -selection clipboard "$filename"
		fi
		#else #this is cleaner, but if the exit codes change then the file would be removed
		#	rm "$filename"
		#fi
	;;
	stop_rec)
		killall -INT ffmpeg # or -2 code
		rm "$lastfile"
	;;
	cancel_rec)
		killall -KILL ffmpeg # or -2 code
		dunstify -a screencap.sh "rec canceled" -t $finished_notif_time
		rm "$lastfile"
	;;
	pause_rec)
		killall -STOP ffmpeg && dunstify -a screencap.sh "rec paused" -t 1000  # or -19 code 
	;;
	resume_rec)
		killall -CONT ffmpeg && dunstify -a screencap.sh "rec resumed" -t 1000 # or -18 code
	;;
	toggle_rec)
		ffmpeg_pid=$(pgrep -P $(pgrep -f "$(basename $0).*cast.*") ffmpeg)
		# pause
		if [ -n "$ffmpeg_pid" ] && [ $? -eq 0 ];then # if both are running
			kill -INT $ffmpeg_pid
			cp -vf "$lastfile" "$lockfile"
			rm "$lastfile"
		# resume
		else
			if [ -s "$lockfile" ];then
				#content_lock="$(cat "$lockfile")"
				defIFS=$IFS
				IFS=$'\n'
				read -r -d'\n' fnl X Y W H < "$lockfile"
				echo $fnl $X $Y $W $H
				IFS=$defIFS
				if [[ "$fnl" =~ .*_select.* ]];then
					ffmpeg_opts_video=${ffmpeg_opts_video/size_to_replace/-s ${W}x${H}}
					ffmpeg_opts_video=${ffmpeg_opts_video/offset_to_replace/+${X},${Y}}
				else 
					ffmpeg_opts_video=${ffmpeg_opts_video/size_to_replace/-s $full_res}
					ffmpeg_opts_video=${ffmpeg_opts_video/offset_to_replace/}
				fi
				filename="${fnl}.tmp_to_concat.${video_ext}"
				dunstify -a screencap.sh "rec started" -t $started_notif_time
				ffmpeg $ffmpeg_opts_video $filename
				ffmpeg_exit_code=$?
				echo $ffmpeg_exit_code
				if [ $ffmpeg_exit_code -eq 255 ] || [ $ffmpeg_exit_code -eq 0 ];then
					out_temp="${fnl}_concat.${video_ext}"
					ffmpeg -f concat -safe 0 -i <(echo -e "file '$fnl'\nfile '$filename'") -c copy "$out_temp"
					mv -vf "$out_temp" "$fnl"
					rm "$filename"
					rm "$lockfile"
					dunstify -a ffmpeg "screencast is $fnl" -t $finished_notif_time
					xclip $xclip_opts -t video/ogg -selection clipboard "$fnl"
				else # this is risky, if the exit codes change then $filename would be removed
					"$filename"
				fi
			else
				dunstify -a screencap.sh "no paused screencast present"
			fi
		fi
	;;
	*)echo -ne "Usage: $0 [shot|shots|shotw|cast|casts|castw|stop_rec|pause_rec|resume_rec|toggle_rec]\n";exit 1;;
esac
exit $?

#[1]: from https://github.com/naelstrof/slop/blob/master/README.md#practical-applications
#[2]: ...2:a]amer... not really fixed, just a workaround ("no such filter" error) (instead of ...2:a] amer...)
#[3]: -filter_complex and -map are from https://trac.ffmpeg.org/wiki/AudioChannelManipulation (Section: Merged audio channel)
