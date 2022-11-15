#!/bin/sh
# vars
orig_dir="$PWD"
echo pwd:$orig_dir
echo='echo'
echo=''

#$echo doas etckeeper commit "$(date +'%Y-%m-%d %H:%M:%S') - $0"

pkglist="pkglist"
pkglistver="pkglist_ver"
fm_add=(
	"$HOME/.config/systemd"
	"$HOME/.lyrics"
	"$HOME/.mpd/playlists"
	"$HOME/.mpd/database"
)
f_add=(
	"$HOME/.config/systemd"
	"$HOME/.lyrics"
	"$HOME/.mpd/playlists"
	"$HOME/.mpd/database"
       	"$HOME/.config/lutris"
       	"$HOME/.config/qutebrowser"
       	"$HOME/.local/share/lutris/banners"
       	"$HOME/.local/share/qutebrowser/sessions"
       	"$HOME/.config/rpcs3"
       	"$HOME/.config/PCSX2"
)
# functions
pkg_list() {
	printf "#" > $HOME/${pkglist}.txt
	printf "#" > $HOME/${pkglist}_aur.txt
	date >> $HOME/${pkglist}.txt
	date >> $HOME/${pkglist}_aur.txt
	printf "\n" >> $HOME/${pkglist}.txt
	printf "\n" >> $HOME/${pkglist}_aur.txt
	pacman -Qqen >> $HOME/${pkglist}.txt
	pacman -Qqem >> $HOME/${pkglist}_aur.txt
}

pkg_list_ver() {
	printf "#" > $HOME/${pkglistver}.txt
	printf "#" > $HOME/${pkglistver}_aur.txt
	date >> $HOME/${pkglistver}.txt
	date >> $HOME/${pkglistver}_aur.txt
	printf "\n" >> $HOME/${pkglistver}.txt
	printf "\n" >> $HOME/${pkglistver}_aur.txt
	pacman -Qen >> $HOME/${pkglistver}.txt
	pacman -Qem >> $HOME/${pkglistver}_aur.txt
}
list_films_animes() {
	cd /F/free_ck/films
	paste <(/bin/ls -tr | xargs -d'\n' du -s | cut -f1) <(/bin/ls -tr | xargs -d'\n' du -s | cut -f2- | xargs -d'\n' ls -d --color=always -U) > ~/filmsanimes_list.txt
	cd "$orig_dir"
	cd /F/free_ck/anime
	echo >> ~/filmsanimes_list.txt
	paste <(/bin/ls -tr | xargs -d'\n' du -s | cut -f1) <(/bin/ls -tr | xargs -d'\n' du -s | cut -f2- | xargs -d'\n' ls -d --color=always -U) >> ~/filmsanimes_list.txt
	cd "$orig_dir"
	#alias lsdt="paste <(/bin/ls -tr | xargs -d'\n' du -s | cut -f1) <(/bin/ls -tr | xargs -d'\n' du -s | cut -f2- | xargs -d'\n' ls -d --color=always -U)"
	#lsdt > ~/filmsanimes_list.txt
}
dostuff_function() {
	cmd="$1"
	echo cmd:$cmd
	$echo pkg_list
	$echo pkg_list_ver
	$echo list_films_animes
	$echo cp -v /I/Raccolte/music_files.txt ~/ 
	$echo $cmd status
	$echo sleep 1
	$echo $cmd add -u
	if [ "$cmd" = "$m" ];then
		for folder_to_add in ${fm_add[@]};do
			$echo $cmd add -v "$folder_to_add"
		done
	elif [ "$cmd" = "$ycmd" ];then
		for folder_to_add in ${f_add[@]};do
			$echo $cmd add -v "$folder_to_add"
		done
	fi
	$echo $cmd status
	$echo $cmd commit -m "$(date +'%Y-%m-%d %H:%M:%S')"
}
dostuff_push() {
	cmd="$1"
	echo cmd_push:$cmd
	$echo $cmd push
}
copyq_function(){
	if ! [ "$1" = "" ];then
		read -p "copyq? [y/n]:" ans
		if [ "$ans" = "y" ];then
			$echo ~/linux-custom-scripts/copyq_push.sh
		fi
	else
		$echo ~/linux-custom-scripts/copyq_push.sh
	fi
}
dovcsh() {
	for repo in $(vcsh list);do
		vcsh $repo status --untracked=no
		vcsh $repo add -vu
		vcsh $repo status --untracked=no
		vcsh $repo commit -m "$(date +'%Y-%m-%d %H:%M:%S')"
		vcsh $repo push
	done
}

# main
m="git --git-dir=$HOME/.config/dotfiles-minimal/dotfiles-minimal.git --work-tree=$HOME -c status.showUntrackedFiles=no"
ycmd="yadm"
if [ -z $1 ];then
	dostuff_function "$ycmd"
	dostuff_function "$m"
	dostuff_push "$ycmd"
	dostuff_push "$m"
	dovcsh
	copyq_function ask
else
	case $1 in
		yadm|y)   dostuff_function "$ycmd";dostuff_push "$ycmd";;
		dotmin|m) dostuff_function "$m";dostuff_push "$m";;
		copyq|cq) copyq_function;;
		vcsh|v) dovcsh;;
		*) echo -e "Usage: $0 [arg]\narg:\n  yadm, y\tyadm funtion\n  dotmin, m\tdotfiles-minimal funtion\n  copyq, cq\texecute $l/copyq_push.sh"
	esac
fi
