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

cast_program="gpu-screen-recorder"

cast_program_options=" -o"

#echo $size_to_replace $offset_to_replace
ffmpeg_opts_image="-f x11grab size_to_replace -i ${DISPLAY}offset_to_replace "
ffmpeg_opts_image+="-vframes 1 -pix_fmt yuv444p "
ffmpeg_opts_image+="-preset fast "

started_notif_time=200
finished_notif_time=10000
paused_notif_time=1000
resumed_notif_time=1000

folder_img="$HOME/Pictures/screens"
folder_video="$HOME/Videos/screencasts"

while getopts i:v:f:h opt;do
	case $opt in
		i)folder_img="$OPTARG";;
		v)folder_video="$OPTARG";;
		f)filename="$OPTARG";;
		h)	echo -ne "Usage: $0 [opt]\n";
			#echo -ne "  -n\t\tdon't be verbose (dont't print processed files)\n";
			echo -ne "  -v [path]\tfolder for screencasts\n";
			echo -ne "  -i [path]\tfolder for screenshots\n";
			echo -ne "  -f [name]\tfilename\n";
			exit 0;;
		?)echo -e "'$opt' Uknown option. Exiting"; exit 2;;
	esac
done

args=($@)
case ${args[$(($OPTIND-1))]} in
	shot)
		filename="${folder_img}/${filename:="${date}"}.${image_ext}"
		ffmpeg_opts_image=${ffmpeg_opts_image/size_to_replace/-s $size_to_replace}
		ffmpeg_opts_image=${ffmpeg_opts_image/offset_to_replace/$offset_to_replace}
		ffmpeg $ffmpeg_opts_image $filename \
			&& dunstify -a ffmpeg "screenshot is $filename" -t $finished_notif_time -I "$filename" \
			&& xclip $xclip_opts -t image/png -selection clipboard "$filename"
			#&& echo $filename | xclip -selection clipboard
	;;
	shots)
		slop=$(slop $slop_opts -f "%x %y %w %h %g %i") || exit 1 #[1]
		filename="${folder_img}/${filename:=${date}}.${image_ext}"
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
		filename="${folder_img}/${filename:="${date}"}.${image_ext}"
		read -r X Y W H < <(echo $slop) #[1]
		ffmpeg_opts_image=${ffmpeg_opts_image/size_to_replace/-s ${W}x${H}}
		ffmpeg_opts_image=${ffmpeg_opts_image/offset_to_replace/+${X},${Y}}
		ffmpeg $ffmpeg_opts_image $filename \
			&& dunstify -a ffmpeg "screenshot is $filename" -t $finished_notif_time -I "$filename" \
			&& xclip $xclip_opts -t image/png -selection clipboard "$filename"
	;;
	cast)
		filename="${folder_video}/${filename:="${date}"}.${video_ext}"
		cast_program_options=${cast_program_options/size_to_replace/-s $size_to_replace}
		cast_program_options=${cast_program_options/offset_to_replace/$offset_to_replace}
		echo "$filename" > "$lastfile"

		dunstify -a screencap.sh "rec started" -t $started_notif_time
		$cast_program $cast_program_options $filename
		cast_program_exit_code=$?
		echo $cast_program_options
		if [ $cast_program_options -eq 255 ] || [ $cast_program_options -eq 0 ];then
			dunstify -a $cast_program "screencast is $filename" -t $finished_notif_time
			xclip $xclip_opts -t video/ogg -selection clipboard "$filename"
		else
			dunstify -a screencap.sh "rec failed" -t $finished_notif_time
		fi
		#else #this is cleaner, but if the exit codes change then the file would be removed
		#	rm "$filename"
		#fi
	;;
	casts)
		slop=$(slop $slop_opts -f "%x %y %w %h %g %i") || exit 1 #[1]
		filename="${folder_video}/${filename:="${date}"}.${video_ext}"
		read -r X Y W H G ID < <(echo $slop) #[1]
		cast_program_options=${cast_program_options/size_to_replace/-s ${W}x${H}}
		cast_program_options=${cast_program_options/offset_to_replace/+${X},${Y}}
		echo -e "$filename\n$X\n$Y\n$W\n$H" > "$lastfile"

		dunstify -a screencap.sh "rec started" -t $started_notif_time
		$cast_program $cast_program_options $filename
		cast_program_options=$?
		echo $cast_program_options
		if [ $cast_program_options -eq 255 ] || [ $cast_program_options -eq 0 ];then
			dunstify -a $cast_program "screencast is $filename" -t $finished_notif_time
			xclip $xclip_opts -t video/ogg -selection clipboard "$filename"
		else
			dunstify -a screencap.sh "rec failed" -t $finished_notif_time
		fi
		#else #this is cleaner, but if the exit codes change then the file would be removed
		#	rm "$filename"
		#fi
	;;
	castw)
		slop=$(xwininfo -id $(xdotool getactivewindow) | awk 'BEGIN{res=""} /Absolute upper|Width|Height/ {res=res$NF" "}END{print res}') || exit 1 #[1]
		filename="${folder_video}/${filename:="${date}"}.${video_ext}"
		read -r X Y W H < <(echo $slop) #[1]
		cast_program_options=${cast_program_options/size_to_replace/-s ${W}x${H}}
		cast_program_options=${cast_program_options/offset_to_replace/+${X},${Y}}
		echo -e "$filename\n$X\n$Y\n$W\n$H" > "$lastfile"

		dunstify -a screencap.sh "rec started" -t $started_notif_time
		$cast_program $cast_program_options $filename
		cast_program_options=$?
		echo $cast_program_options
		if [ $cast_program_options -eq 255 ] || [ $cast_program_options -eq 0 ];then
			dunstify -a $cast_program "screencast is $filename" -t $finished_notif_time
			xclip $xclip_opts -t video/ogg -selection clipboard "$filename"
		else
			dunstify -a screencap.sh "rec failed" -t $finished_notif_time
		fi
		#else #this is cleaner, but if the exit codes change then the file would be removed
		#	rm "$filename"
		#fi
	;;
	stop_rec)
		killall -INT $cast_program # or -2 code
		rm "$lastfile"
	;;
	cancel_rec)
		killall -KILL $cast_program # or -2 code
		dunstify -a screencap.sh "rec canceled" -t $finished_notif_time
		rm -v $(cat "$lastfile")
		rm "$lastfile"
	;;
	pause_rec)
		killall -STOP $cast_program && dunstify -a screencap.sh "rec paused" -t 1000  # or -19 code 
	;;
	resume_rec)
		killall -CONT $cast_program && dunstify -a screencap.sh "rec resumed" -t 1000 # or -18 code
	;;
	toggle_rec)
		ffmpeg_pid=$(pgrep -P $(pgrep -f "$(basename $0).*cast.*") $cast_program)
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
					cast_program_options=${cast_program_options/size_to_replace/-s ${W}x${H}}
					cast_program_options=${cast_program_options/offset_to_replace/+${X},${Y}}
				else 
					cast_program_options=${cast_program_options/size_to_replace/-s $full_res}
					cast_program_options=${cast_program_options/offset_to_replace/}
				fi
				filename="${fnl}.tmp_to_concat.${video_ext}"
				dunstify -a screencap.sh "rec started" -t $started_notif_time
				$cast_program $cast_program_options $filename
				cast_program_options=$?
				echo $cast_program_options
				if [ $cast_program_options -eq 255 ] || [ $cast_program_options -eq 0 ];then
					out_temp="${fnl}_concat.${video_ext}"
					ffmpeg -f concat -safe 0 -i <(echo -e "file '$fnl'\nfile '$filename'") -c copy "$out_temp"
					mv -vf "$out_temp" "$fnl"
					rm "$filename"
					rm "$lockfile"
					dunstify -a $cast_program "screencast is $fnl" -t $finished_notif_time
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
