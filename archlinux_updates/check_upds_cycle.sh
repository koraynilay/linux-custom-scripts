#!/bin/sh
while true;do
	ups=`checkupdates`
	if [[ -n $ups ]];then
		act=`dunstify -a Updates -A "update,up" "Updates are available"`
		! [[ -z $act ]] && updates_dialog
#		! [[ -z $act ]] && termite --hold --title="archlinux_updates_script" -e "zsh -c 'printf \"Updates available:\n\n$ups\n\n\";~/linux-custom-scripts/ans_updates.sh'"
#		read ans; echo $ans;if [ \"$ans\" = \"y\" ];then pacman -Syu;fi;sleep 10'"
	#	termite --hold -e 'sh -c "printf \"Updates available:\n\n\"; checkupdates"'
	else
		echo no_updates
	fi
	sleep 3600
done
