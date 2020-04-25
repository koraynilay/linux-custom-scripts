#!/bin/sh
dest="/root/dotfiles-minimal/config"
dest2="/root/dotfiles-minimal"

copy(){
	printf "copying \"$conf\" to $dest\n"
	cp -r "$conf" "$dest"
}
copy_files(){
	printf "copying \"$conf\" to $dest\n"
	confdir=$(echo $conf | awk '/root\/.config/ {split($0,a,"/");print a[4]}')
	mkdir -p $dest/$confdir
	cp -r "$conf" "$dest/$confdir"
}
copy2(){
	printf "copying \"$conf2\" to $dest2\n"
	cp -r "$conf2" "$dest2"
}
copy_files2(){
	printf "copying \"$conf2\" to $dest2\n"
	confdir2=$(echo $conf2 | awk '/root/ {split($0,a,"/");print a[4]}')
	mkdir -p $dest/$confdir2
	cp -r "$conf2" "$dest/$confdir2"
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
		/root/.config/SpeedCrunch) copy;;
		/root/.config/kdeconnect) copy;;
#		/root/.config/systemd) copy;;
		/root/.config/ferdi-themes) copy;;
		/root/.config/herbstluftwm) copy;;
		/root/.config/leafpad) copy;;
		/root/.config/peaclock) copy;;
		/root/.config/shalarm) copy;;
		/root/.config/user-dirs.dirs) copy;;
		/root/.config/user-dirs.locale) copy;;
		*) continue;;
	esac
done
for conf in /root/.config/*/*;do
	case $conf in
		/root/.config/gtk-3.0/settings.ini) copy_files;;
		/root/.config/gzdoom/gzdoom.ini) copy_files;;
		/root/.config/gzdoom/saves) copy_files;;
		/root/.config/google-chrome/configs) copy_files;;
		/root/.config/viewnior/viewnior.conf) copy;;
		*) continue;;
	esac
done
for conf2 in /root/.*;do
	case $conf2 in
		/root/.zshrc) copy2;;
		/root/.zsh_history) copy2;;
		/root/.oh-my-zsh) copy_zsh;;
#
		/root/.ashrc) copy2;;
		/root/.bash_history) copy2;;
#
		/root/.ncmpcpp) copy2;;
		/root/.ideskrc) copy2;;
		/root/.idesktop) copy2;;
		/root/.xinitrc) copy2;;
		/root/.gtkrc-2.0) copy2;;
		/root/.vimrc) copy2;;
		/root/.vim) copy2;;
		/root/.kde4) copy2;;
		/root/.lesshst) copy2;;
		/root/.node_repl_history) copy2;;
		/root/.assaultcube) copy2;;
		/root/.fehbg) copy2;;
		*) continue;;
	esac
done
for conf2 in /root/.*/*;do
	case $conf2 in
		/root/.mpd/playlists) copy_files2;;
		*) continue;;
	esac
done
