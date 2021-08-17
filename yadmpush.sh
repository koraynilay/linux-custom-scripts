#!/bin/sh
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
	pkg_list
	pkg_list_ver
	list_films_animes
	cp -v /I/Raccolte/music_files.txt ~/ 
	$cmd status
	sleep 1
	$cmd add -u
	for folder_to_add in $f_add;do
		$cmd add -v "$folder_to_add"
	done
	$cmd status
	$cmd commit -m "$(date +'%Y-%m-%d %H:%M:%S')"
	$cmd push
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

orig_dir="$PWD"
echo pwd:$orig_dir
echo='echo'
echo=''

pkglist="pkglist"
pkglistver="pkglist_ver"
f_add=(
	"$HOME/.lyrics"
	"$HOME/.mpd/playlists"
	"$HOME/.mpd/database"
       	"$HOME/.config/lutris"
)

m="git --git-dir=$HOME/.config/dotfiles-minimal/dotfiles-minimal.git --work-tree=$HOME -c status.showUntrackedFiles=no"
ycmd="yadm"
if [ -z $1 ];then
	$echo dostuff_function "$ycmd"
	$echo copyq_function ask
	$echo dostuff_function "$m"
else
	case $1 in
		yadm|y) $echo dostuff_function "$ycmd";;
		dotmin|m) $echo dostuff_function "$m";;
		copyq|cq) $echo copyq_function;;
		*) echo -e "Usage: $0 [arg]\narg:\n  yadm, y\tyadm funtion\n  dotmin, m\tdotfiles-minimal funtion\n  copyq, cq\texecute $l/copyq_push.sh"
	esac
fi

#f=()

# deprecated
#m_function() {
#	m="git --git-dir=$HOME/.config/dotfiles-minimal/dotfiles-minimal.git --work-tree=$HOME -c status.showUntrackedFiles=no"
#	pkg_list
#	pkg_list_ver
#	list_films_animes
#	cp -v /I/Raccolte/music_files.txt ~/ 
#	$m status
#	sleep 1
#	$m add -u
#	for folder_to_add in $f_add;do
#		$m add -v "$folder_to_add"
#	done
#	$m status
#	$m commit -m "$(date +'%Y-%m-%d %H:%M:%S')"
#	$m push
#}
#yadm_function() {
#	ycmd="yadm"
#	pkg_list
#	pkg_list_ver
#	list_films_animes
#	cp -v /I/Raccolte/music_files.txt ~/ 
#	$ycmd status
#	sleep 1
#	$ycmd add -u
#	for folder_to_add in $f_add;do
#		$ycmd add -v "$folder_to_add"
#	done
#	$ycmd status
#	$ycmd commit -m "$(date +'%Y-%m-%d %H:%M:%S')"
#	$ycmd push
#}
