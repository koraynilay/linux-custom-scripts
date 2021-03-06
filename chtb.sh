#!/bin/bash
#browser_folder="chromium"
browser_folder="google-chrome"
#browser_folder="BraveSoftware/Brave-Browser"
folders=("$HOME/.config/$browser_folder/Default/Sessions" "$HOME/.config/$browser_folder/Profile 1/Sessions")
bck_folder="$HOME/.chtb"
copy_folder_whole=1
folder_basename_level=2 # to pass to cut, these are the last n fields
#filenames=""
lvl=0
usage() {
	echo -e "Usage: $0 [options] action"
	echo -e ""
	echo -e " action:"
	echo -e "  b, backup\tBacks up chromium/google-chrome current session (tabs) in ~/.chtb/[profile name]"
	echo -e "  r, restore\tRestores the backed up chromium/google-chrome session (tabs) from ~/.chtb/[profile name]"
	echo -e ""
	echo -e " options:"
	echo -e "  -h\t\tShow this help and exit"
	#echo -e " -v\tBe verbose"
	echo -e "  -o opts\tAdd any cp option (ex. $0 -o -i)"
	echo -e "  -l\t\tEnables the backup in levels (~/.chtb%d%m%Y%H%M%S) (date --help)"
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
			if [ $copy_folder_whole -eq 1 ];then
				bn=${bck_folder}/$(echo "$it" | rev | cut -d'/' -f2 | rev)
				rn=${bck_folder}/$(echo "$it" | rev | cut -d'/' -f-2 | rev)
				rm -rv "${rn}/"
				#rm -rIv "${rn}/"
				cp -vr "${it}" "${bn}/"
			else
				bn=${bck_folder}/$(basename "$it")
				if [ ! -d "$bn" ];then
					mkdir -p "$bn"
				fi
				cp -v "${it}/Current Tabs" "${it}/Current Session" "${bn}/"
			fi
		done
		;;
	r|restore)
		if [ ! -d $bck_folder ];then
			echo -ne "'$bck_folder' doesn't exist"
			exit 1
		fi
		for ((i=0;i<${#folders[@]};i++));do
			it="${folders[i]}"
			if [ $copy_folder_whole -eq 1 ];then
				bn=${bck_folder}/$(echo "$it" | rev | cut -d'/' -f-2 | rev)
				if [ ! -d "$bn" ];then
					continue
				fi
				cp -Tvir "${bn}" "${it}/"
			else
				bn=${bck_folder}/$(basename "$it")
				if [ ! -d "$bn" ];then
					continue
				fi
				cp -iv "${bn}/Current Tabs" "${bn}/Current Session" "${it}/"
			fi
		done
		;;
	*)
		usage
		exit 3
		;;
esac
yadm add --verbose "$bck_folder" #or -v
if [ $lvl -eq 1 ];then
	cp -rv "$bck_folder" "${bck_folder}$(date +%d%m%Y%H%M%S)" # ddmmYYYYHHMMSS (dd = day, mm = month, YYYY = year, HH = hour, MM = minute)
fi
