#!/bin/sh
id=$1
v=0
f=0
while getopts hvf: opt;do
	case $opt in
		f)folder=$OPTARG;f=1;;
		v)v=1;;
		h)echo -e "Error";exit 1;;
	esac
done
if [ $v -eq 1 ];then
	echo -e $id: $(curl -s "https://store.steampowered.com/app/$id" | grep -Po '(?<=<div class="apphub_AppName">).*(?=</div>)')
else
	curl -s "https://store.steampowered.com/app/$id" | grep -Po '(?<=<div class="apphub_AppName">).*(?=</div>)'
fi
if [ $f -eq 1 ];then
	for iid in $folder/*;do 
		echo $iid
		echo "curl -s https://store.steampowered.com/app/$(basename $iid) | grep -Po '(?<=<div class="apphub_AppName">).*(?=</div>)'"
	done
fi
