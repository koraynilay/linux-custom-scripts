#!/bin/sh
dest="/root/dotfiles-minimal/config"
dest2="/root/dotfiles-minimal"

copy(){
	printf "copying \"$conf\" to $dest\n"
	cp -r "$conf" "$dest"
}
copy2(){
	printf "copying \"$conf2\" to $dest2\n"
	cp -r "$conf2" "$dest2"
}

copy_zsh(){
	printf "copying \"$conf2/custom\" to $dest2/omz/custom\n"
	cp -r "$conf2/custom" "$dest2/omz/custom"
}

for conf in /root/.config/*;do
	case $conf in
		/root/.config/bck_config.sh) continue;;
		/root/.config/bck_config_minimal.sh) continue;;
		/root/.config/i3) copy;;
		/root/.config/picom.conf) copy;;
		/root/.config/picom_launch.sh) copy;;
		/root/.config/polybar) copy;;
		/root/.config/termite) copy;;
		/root/.config/dunst) copy;;
		/root/.config/cava) copy;;
		/root/.config/htop) copy;;
		/root/.config/neofetch) copy;;
		/root/.config/mpd) copy;;
		/root/.config/rofi) copy;;
		/root/.config/ranger) copy;;
		/root/.config/vlc) copy;;
		/root/.config/SpeedCrunch) copy;;
		/root/.config/systemd) copy;;
		*) continue;;
	esac
done
for conf2 in /root/.*;do
	case $conf2 in
		/root/.fonts) copy2;;
		/root/.mpd) copy2;;
		/root/.ncmpcpp) copy2;;
		/root/.oh-my-zsh) copy_zsh;;
		/root/.xinitrc) copy2;;
		/root/.zshrc) copy2;;
		*) continue;;
	esac
done
