#!/bin/sh
swapfile=/swpfl.sys
[[ $UID -ne 0 ]] && echo -e "This script needs root access. Exiting." && exit 1
if [ "$1" = "off" ];then
	swapoff "$swapfile" -v
	rm "$swapfile"
elif [ "$1" = "on" ];then
	fallocate -l 13G "$swapfile"
	chmod 0600 "$swapfile"
	mkswap "$swapfile"
	swapon "$swapfile" -v
	chattr +d /swpfl.sys
else
	echo -e "Usage: $0 [on|off]"
fi
