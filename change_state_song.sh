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
		lend=$(($(grep -n Endtr "${filename}" | cut -f1 -d:)-1))
		for line in $(sed -n -e "${lstart},${lend}p" "${filename}");do
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
			#echo $mf $sf
			mc=$((10#$mc))
			sc=$((10#$sc))
			mf=$((10#$mf))
			sf=$((10#$sf))
			if [[ $mc -lt $mf ]];then
				if [ "$1" == "prev" ];then
					echo seek ${lasttc[i-2]}
					mpc  seek ${lasttc[i-2]}
				elif [ "$1" == "next" ];then
					echo seek $timef
					mpc  seek $timef
				fi
				songstate_change_notif " - $title"
				exit
			fi
			lasttc[i]=$timef #time start, for prev
			let i++
		done
	fi
}

case $1 in
	next) ch next;;
	prev) ch prev;;
	*)mpc $@;;
esac
