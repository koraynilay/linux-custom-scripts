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
copy_files(){
	printf "copying \"$conf\" to $dest\n"
	confdir=$(echo $conf | awk '/root\/.config/ {split($0,a,"/");print a[4]}')
	mkdir -p $dest/$confdir
	cp -r "$conf" "$dest/$confdir"
}

copy_zsh(){
	mkdir -p $dest2/omz
	printf "copying \"$conf2/custom\" to $dest2/omz/custom\n"
	cp -r "$conf2/custom/themes" "$dest2/omz/custom"
	cp -r "$conf2/custom/example.zsh" "$dest2/omz/custom"
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
		/root/.config/gtk-3.0/settings.ini) copy;;
		/root/.config/gzdoom/gzdoom.ini) copy;;
		/root/.config/gzdoom/saves) copy;;
		*) continue;;
	esac
done
for conf in /root/.config/*/*;do
	case $conf in
		/root/.config/gtk-3.0/settings.ini) copy_files;;
		/root/.config/gzdoom/gzdoom.ini) copy_files;;
		/root/.config/gzdoom/saves) copy_files;;
		*) continue;;
	esac
done
for conf2 in /root/.*;do
	case $conf2 in
		/root/.ncmpcpp) copy2;;
		/root/.oh-my-zsh) copy_zsh;;
		/root/.zshrc) copy2;;
		/root/.xinitrc) copy2;;
		/root/.gtkrc-2.0) copy2;;
		/root/.vimrc) copy2;;
		/root/.vim) copy2;;
		*) continue;;
	esac
done
