#!/bin/bash
lyrdir="$HOME/.lyrics"
case $1 in
	next) next;;
	prev) prev;;
	*)mpc $1;;
esac
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
	if [ -f "$filename"];then
		lstart=$(($(grep -n Tracklist "${filename}" | cut -f1 -d:)+1))
		lend=$(($(grep -n Endtr "${filename}" | cut -f1 -d:)-1))
		for line in $(sed -n -e "${lstart},${lend}p" "${filename}");do
			timec=$(mpc status | sed -n -e '2p' | awk '{gsub(/\/.*/,"",$3);print $3}')
			mc=$(echo $timec | awk -F: '{print $(NF-1)}')
			sc=$(echo $timec | awk -F: '{print $(NF-0)}')
			timef=$(echo $line | awk '{print $1}')
			#echo $timef
			mf=$(echo $timef | awk -F: '{print $(NF-1)}')
			sf=$(echo $timef | awk -F: '{print $(NF-0)}')
			#echo $mf $sf
			if [[ $s -le  ]];then

			fi
			lasttc=$time
		fi
	fi
}
