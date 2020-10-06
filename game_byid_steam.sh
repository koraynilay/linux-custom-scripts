#!/bin/sh
v=0
f=0
while getopts hvdf: opt;do
	case $opt in
		f)folder=$OPTARG;f=1;;
		v)v=1;;
		h)echo -e "Error";exit 1;;
		d)id=$OPTARG;;
	esac
done
if [ $# -gt 3 ];then
	if [ $f -eq 1 ];then
		for iid in $folder/*;do 
			id=$(basename $iid)
			if [ $v -eq 1 ];then
				echo $id: $(curl -s https://store.steampowered.com/app/$id | grep -Po '(?<=<div class="apphub_AppName">).*(?=</div>)')
			else
				curl -s https://store.steampowered.com/app/$id | grep -Po '(?<=<div class="apphub_AppName">).*(?=</div>)'
			fi
		done
	fi
else
	if [ $v -eq 1 ];then
		id=$2
		echo $id: $(curl -s "https://store.steampowered.com/app/$id" | grep -Po '(?<=<div class="apphub_AppName">).*(?=</div>)')
	else
		id=$1
		curl -s "https://store.steampowered.com/app/$id" | grep -Po '(?<=<div class="apphub_AppName">).*(?=</div>)'
	fi
fi
