#!/bin/sh
v=0
f=0
while getopts hvd:f: opt;do
	case $opt in
		f)folder=$OPTARG;f=1;;
		v)v=1;;
		h)echo -e "-h help\n-v verbose (show id)\n-f subfolders of this folder are steam ids\n-d with -f, add id";exit 1;;
		d)id=$OPTARG;;
	esac
done
if [ $# -gt 2 ];then
	if [ $f -eq 1 ];then
		for current in $folder/*;do 
			id=$(basename $current)
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
