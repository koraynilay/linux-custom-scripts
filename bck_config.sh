#!/bin/sh
dest="/root/dotfiles/config"
for conf in /root/.config/*;do
	case $conf in
		/root/.config/Ferdi) continue;;
		/root/.config/discord) continue;;
		/root/.config/unity3d) continue;;
		/root/.config/Mailspring) continue;;
		/root/.config/databases) continue;;
		/root/.config/Network\ Persistent\ State) continue;;
	esac
	printf "copying \"$conf\" to $dest\n"
	cp -r "$conf" "$dest"
done
#for conf in *;do
#	if [ "$conf" = "Ferdi" ];then # | "$conf" = "discord" | "$conf" = "unity3d" ];then
#		continue
#	else
#		echo $conf
#	       	#cp -r $conf /root/dotfiles/
#	fi
#done
