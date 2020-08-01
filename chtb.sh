#!/bin/bash
folders=("$HOME/.config/google-chrome/Default" "$HOME/.config/google-chrome/Profile 1")
bck_folder="$HOME/.chtb"
usage() {
	echo -e "Usage: $0"
	exit 0
}
case $1 in
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
			#echo ${folders[i]}
			#echo cp $@ \"${folders[i]}/Current Tabs\" \"${folders[i]}/Current Session\" \"${bck_folder}/$(basename "${folders[i]}")/
			it="${folders[i]}"
			bn=${bck_folder}/$(basename "$it")
			if [ ! -d "$bn" ];then
				continue
			fi
			cp -v "${bn}/Current Tabs" "${bn}/Current Session" "${bn}/"
		done
		;;
esac
