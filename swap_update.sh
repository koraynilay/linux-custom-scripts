#!/bin/sh
swapfile=/C/swpfl.sys
g=16
[[ $UID -ne 0 ]] && echo -e "This script needs root access. Exiting." && exit 1
if [ "$1" = "off" ];then
	swapoff "$swapfile" -v
	rm "$swapfile"
elif [ "$1" = "on" ];then
	fallocate -l ${g}G "$swapfile"
	chmod 0600 "$swapfile"
	mkswap "$swapfile"
	swapon "$swapfile" -v
	chattr +d /swpfl.sys
else
	echo -e "Usage: $0 [on|off]"
fi
