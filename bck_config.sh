#!/bin/sh
dest="/root/dotfiles/config"
for conf in /root/.config/*;do
	case $conf in
		/root/.config/bck_config.sh) continue;;
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
printf "copying \"/root/.oh-my-zsh\" to /root/dotfiles/oh-my-zsh\n"
cp -r /root/.oh-my-zsh /root/dotfiles && rm -r /root/dotfiles/oh-my-zsh && mv /root/dotfiles/.oh-my-zsh /root/dotfiles/oh-my-zsh && rm -r /root/dotfiles/oh-my-zsh/.git /root/dotfiles/oh-my-zsh/.github
printf "copying \"/root/.xinitrc\" to /root/dotfiles/xinitrc\n"
cp -r /root/.xinitrc /root/dotfiles/xinitrc
printf "copying \"/root/.zshrc\" to /root/dotfiles/zshrc\n"
cp -r /root/.zshrc /root/dotfiles/zshrc
printf "copying \"/root/.zsh_history\" to /root/dotfiles/zsh_history\n"
cp -r /root/.zsh_history /root/dotfiles/zsh_history
#for conf in *;do
#	if [ "$conf" = "Ferdi" ];then # | "$conf" = "discord" | "$conf" = "unity3d" ];then
#		continue
#	else
#		echo $conf
#	       	#cp -r $conf /root/dotfiles/
#	fi
#done
