#!/bin/bash
folders=("$HOME/.config/google-chrome/Default" "$HOME/.config/google-chrome/Profile 1")
bck_folder="$HOME/.chtb"
lvl=0
usage() {
	echo -e "Usage: $0 [options] action"
	echo -e ""
	echo -e " action:"
	echo -e "  b, backup\tBacks up google-chome current session (tabs) in ~/.chtb/[profile name]"
	echo -e "  r, restore\tRestores the backed up google-chome session (tabs) from ~/.chtb/[profile name]"
	echo -e ""
	echo -e " options:"
	echo -e "  -h\t\tShow this help and exit"
	#echo -e " -v\tBe verbose"
	echo -e "  -o opts\tAdd any cp option (ex. $0 -o -i)"
}
while getopts hlo: opt;do
	case $opt in
		#v)verbose=1;;
		h)usage;exit 0;;
		o)cp_opt="$OPTARG";;
		l)lvl=1;;
		?)exit 2;;
	esac
done
act=$(echo $@ | grep -oE "b|backup|r|restore")
case $act in
	b|backup)
		if [ ! -d $bck_folder ];then
			echo -ne "'$bck_folder' doesn't exist, create it? [y/n]: "
			read -r yn
			if [ "$yn" = "y" ];then 
				mkdir -p "$bck_folder"
			else exit 1
			fi
		fi
		for ((i=0;i<${#folders[@]};i++));do
			#echo ${folders[i]}
			#echo cp $@ \"${folders[i]}/Current Tabs\" \"${folders[i]}/Current Session\" \"${bck_folder}/$(basename "${folders[i]}")/
			it="${folders[i]}"
			bn=${bck_folder}/$(basename "$it")
			if [ ! -d "$bn" ];then
				mkdir -p "$bn"
			fi
			cp -v "${it}/Current Tabs" "${it}/Current Session" "${bn}/"
		done
		;;
	r|restore)
		if [ ! -d $bck_folder ];then
			echo -ne "'$bck_folder' doesn't exist"
			exit 1
		fi
		for ((i=0;i<${#folders[@]};i++));do
			it="${folders[i]}"
			bn=${bck_folder}/$(basename "$it")
			if [ ! -d "$bn" ];then
				continue
			fi
			cp -iv "${bn}/Current Tabs" "${bn}/Current Session" "${it}/"
		done
		;;
	*)
		usage
		exit 3
		;;
esac
if [ $lvl -eq 1 ];then
	cp -rv "$bck_folder" "${bck_folder}$(date +%d%m%Y%H%M%S)" # ddmmYYYYHHMMSS (dd = day, mm = month, YYYY = year, HH = hour, MM = minute)
fi
