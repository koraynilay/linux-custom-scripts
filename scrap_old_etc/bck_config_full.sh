#!/bin/sh
dest="/root/dotfiles-full/config"
dest2="/root/dotfiles-full"

copy(){
	printf "copying \"$conf\" to $dest\n"
	cp -r "$conf" "$dest"
}
copy2(){
	printf "copying \"$conf2\" to $dest2\n"
	cp -r "$conf2" "$dest2"
}

copy_zsh(){
	mkdir -p $dest2/omz
	printf "copying \"$conf2/custom\" to $dest2/omz/custom\n"
	cp -r "$conf2/custom" "$dest2/omz/"
	#cp -r "$conf2/custom/example.zsh" "$dest2/omz/custom"
	#cp -r "$conf2/custom/example.zsh" "$dest2/omz/custom"
}
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
	copy
done
for conf2 in /root/.*;do
	case $conf2 in
		/root/.atom) continue;;
		/root/.flashTool) continue;;
		/root/.cache) continue;;
		/root/.config) continue;;
		/root/.local) continue;;
		/root/.*.swp) continue;;
		/root/.*.swo) continue;;
		/root/.gnupg) continue;;
		/root/.mozilla) continue;;
		/root/.nv) continue;;
		/root/.local) continue;;
		/root/.*.pre-oh-my-zsh*) continue;;
		/root/.steam*) continue;;
		/root/.wine) continue;;
		/root/.ssh) continue;;
		/root/.zcompdump-*-*) continue;;
		/root/.) continue;;
		/root/..) continue;;
		/root/.oh-my-zsh) copy_zsh;;
	esac
	copy2
done

rm -r $dest2/.oh-my-zsh



#printf "copying \"/root/.oh-my-zsh\" to /root/dotfiles/oh-my-zsh\n"
#cp -r /root/.oh-my-zsh /root/dotfiles && rm -r /root/dotfiles/oh-my-zsh && mv /root/dotfiles/.oh-my-zsh /root/dotfiles/oh-my-zsh && rm -r /root/dotfiles/oh-my-zsh/.git /root/dotfiles/oh-my-zsh/.github
#printf "copying \"/root/.xinitrc\" to /root/dotfiles/xinitrc\n"
#cp -r /root/.xinitrc /root/dotfiles/xinitrc
#printf "copying \"/root/.zshrc\" to /root/dotfiles/zshrc\n"
#cp -r /root/.zshrc /root/dotfiles/zshrc
#printf "copying \"/root/.zsh_history\" to /root/dotfiles/zsh_history\n"
#cp -r /root/.zsh_history /root/dotfiles/zsh_history
#for conf in *;do
#	if [ "$conf" = "Ferdi" ];then # | "$conf" = "discord" | "$conf" = "unity3d" ];then
#		continue
#	else
#		echo $conf
#	       	#cp -r $conf /root/dotfiles/
#	fi
#done
