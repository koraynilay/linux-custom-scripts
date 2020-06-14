#!/bin/sh
while true;do
	sleep 0.5
	pgrep scrnsvr
	echo $?
	if [ $? -eq 1 ];then
		dunstify -t 100000 -a script 'scrnsvr crashed'
	fi
done
