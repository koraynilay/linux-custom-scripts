#!/bin/bash
lyrdir="$HOME/.lyrics"
check_dir(){
	if ! [ -d "$lyrdir" ];then
		echo "'$lyrdir' doesn't exists"
		exit 1
	fi
}
ch(){
	check_dir
	i=0
	IFS=$'\n'
	filename="${lyrdir}/$(mpc current).txt"
	if [ -f "$filename" ];then
		lstart=$(($(grep -n Tracklist "${filename}" | cut -f1 -d:)+1))
		lend=$(($(grep -n Endtr "${filename}" | cut -f1 -d:)))
		for line in $(sed -n -e "${lstart},${lend}p" "${filename}");do
			if [ "$line" == "Endtr" ];then
				mpc next
			fi
			timec=$(mpc status | sed -n -e '2p' | awk '{gsub(/\/.*/,"",$3);print $3}')
			mc=$(echo $timec | awk -F':' '{print $(NF-1)}')
			sc=$(echo $timec | awk -F':' '{print $(NF-0)}')
			timef=$(echo $line | awk -F'=' '{gsub(/[ \t]+$/, "", $1);print $1}')
			title=$(echo $line | awk -F'=' '{gsub(/[ \t]+$/, "", $2);print $2}')
			#echo $mc $sc
			#echo $timef
			#echo $lasttc
			mf=$(echo $timef | awk -F: '{s=$NF;m=$(NF-1);if($(NF-2) != $0)m+=($(NF-2)*60);print m}')
			sf=$(echo $timef | awk -F: '{s=$NF;m=$(NF-1);if($(NF-2) != $0)m+=($(NF-2)*60);print s}')
			echo $mf $sf
			mc=$((10#$mc))
			sc=$((10#$sc))
			mf=$((10#$mf))
			sf=$((10#$sf))
			if [[ $mc -lt $mf ]];then
				if [ "$1" == "prev" ];then
					echo seek ${lasttc[i-2]}
					if [ "${lasttc[i-2]}" == "00:00" ];then
						mpc prev
					else
						mpc  seek ${lasttc[i-2]}
					fi
					songstate_change_notif " - ${lasttt[i-2]}"
				elif [ "$1" == "next" ];then
					echo seek $timef
					#length=$(mpc status | sed -n -e '2p' | awk '{gsub(/.*\//,"",$3);print $3}')
					#if [ "$timef" == "$length" ];then
					#	mpc next
					#else
					#	mpc  seek $timef
					#fi
					mpc  seek $timef
					songstate_change_notif " - $title"
				fi
				return 0
			fi
			lasttc[i]=$timef #time start, for prev
			lasttt[i]=$title #time start, for prev
			let i++
		done
	else
		dunstify -t 3000 -u LOW -r 3 -p -a change_stage_song.sh "no lyrics file"
	fi
}

cur=$(mpc current)
if [[ "$cur" =~ "[Full OST]"$ ]];then
	case $1 in
		next)
			ch next
			echo next
			if [ $? -ne 0 ];then
				mpc next
			fi
			;;
		prev)
			ch prev
			if [ $? -ne 0 ];then
				mpc prev
			fi
			echo prev
			;;
		*)mpc $@;;
	esac
else
	mpc $@
fi
