#!/bin/bash
lyrdir="$HOME/.lyrics"
check_dir(){
	if ! [ -d "$lyrdir" ];then
		echo "'$lyrdir' doesn't exists"
		exit 1
	fi
}
next(){
	check_dir
	IFS=$'\n'
	filename="${lyrdir}/$(mpc current).txt"
	if [ -f "$filename" ];then
		lstart=$(($(grep -n Tracklist "${filename}" | cut -f1 -d:)+1))
		lend=$(($(grep -n Endtr "${filename}" | cut -f1 -d:)-1))
		for line in $(sed -n -e "${lstart},${lend}p" "${filename}");do
			timec=$(mpc status | sed -n -e '2p' | awk '{gsub(/\/.*/,"",$3);print $3}')
			mc=$(echo $timec | awk -F: '{print $(NF-1)}')
			sc=$(echo $timec | awk -F: '{print $(NF-0)}')
			timef=$(echo $line | awk '{print $1}')
			#echo $mc $sc
			#echo $timef
			mf=$(echo $timef | awk -F: '{s=$NF;m=$(NF-1);if($(NF-2) != $0)m+=($(NF-2)*60);print m}')
			sf=$(echo $timef | awk -F: '{s=$NF;m=$(NF-1);if($(NF-2) != $0)m+=($(NF-2)*60);print s}')
			echo $mf $sf
			mc=$((10#$mc))
			sc=$((10#$sc))
			mf=$((10#$mf))
			sf=$((10#$sf))
			if [[ $mc -lt $mf ]];then
				echo ciao $timef
				mpc seek $timef
				songstate_change_notif
				exit
			#elif [[ $mc -eq $mf ]];then
			#	if [[ $sc -le $sf ]];then
			#		echo ciao $timef
			#		mpc seek $timef
			#		songstate_change_notif
			#		exit
			#	fi
			fi
			lasttc=$timef #time start, for prev
		done
	fi
}

case $1 in
	next) next;;
	prev) prev;;
	*)mpc $1;;
esac
