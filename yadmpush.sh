#!/bin/sh
pkglist="pkglist"
pkglistver="pkglist_ver"
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
	paste <(/bin/ls -tr | xargs -d'\n' du -s | cut -f1) <(/bin/ls -tr | xargs -d'\n' du -s | cut -f2- | xargs -d'\n' ls -d --color=always -U) > ~/filmsanimes_list_zips.txt
	#alias lsdt="paste <(/bin/ls -tr | xargs -d'\n' du -s | cut -f1) <(/bin/ls -tr | xargs -d'\n' du -s | cut -f2- | xargs -d'\n' ls -d --color=always -U)"
	#lsdt > ~/filmsanimes_list_zips.txt
}

pkg_list
pkg_list_ver
list_films_animes
yadm status
sleep 1
yadm add -u
yadm add -v ~/.lyrics
yadm add -v ~/.mpd/playlists/
yadm add -v ~/.mpd/database
yadm status
yadm commit -m "$(date +'%Y-%m-%d %H:%M:%S')"
yadm push
read -p "copyq? [y/n]:" ans
if [ "$ans" = "y" ];then
	~/linux-custom-scripts/copyq_push.sh
fi
#f=()
