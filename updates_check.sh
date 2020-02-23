#!/bin/sh
while true;do
	ups=`checkupdates`
	if [[ -n $ups ]];then
		act=`dunstify -a Updates -A "update,up" "Updates are available"`
		! [[ -z $act ]] && termite --hold -e "sh -c 'printf \"Updates available:\n\n$ups\n\n\";read ans; if [ \"$ans\" = \"y\" ];then pacman -Syu;fi'"
	#	termite --hold -e 'sh -c "printf \"Updates available:\n\n\"; checkupdates"'
	fi
	echo fatto
	sleep 3600
done
