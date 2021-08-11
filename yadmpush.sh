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
	paste <(/bin/ls -tr | xargs -d'\n' du -s | cut -f1) <(/bin/ls -tr | xargs -d'\n' du -s | cut -f2- | xargs -d'\n' ls -d --color=always -U) > ~/filmsanimes_list.txt
	cd /F/free_ck/anime
	echo >> ~/filmsanimes_list.txt
	paste <(/bin/ls -tr | xargs -d'\n' du -s | cut -f1) <(/bin/ls -tr | xargs -d'\n' du -s | cut -f2- | xargs -d'\n' ls -d --color=always -U) >> ~/filmsanimes_list.txt
	#alias lsdt="paste <(/bin/ls -tr | xargs -d'\n' du -s | cut -f1) <(/bin/ls -tr | xargs -d'\n' du -s | cut -f2- | xargs -d'\n' ls -d --color=always -U)"
	#lsdt > ~/filmsanimes_list.txt
}

m_function() {
	m="git --git-dir=$HOME/.config/dotfiles-minimal/dotfiles-minimal.git --work-tree=$HOME -c status.showUntrackedFiles=no"
	pkg_list
	pkg_list_ver
	list_films_animes
	cp -v /I/Raccolte/music_files.txt ~/ 
	$m status
	sleep 1
	$m add -u
	$m add -v ~/.lyrics
	$m add -v ~/.mpd/playlists/
	$m add -v ~/.mpd/database
	$m status
	$m commit -m "$(date +'%Y-%m-%d %H:%M:%S')"
	$m push
}
yadm_function() {
	pkg_list
	pkg_list_ver
	list_films_animes
	cp -v /I/Raccolte/music_files.txt ~/ 
	yadm status
	sleep 1
	yadm add -u
	yadm add -v ~/.lyrics
	yadm add -v ~/.mpd/playlists/
	yadm add -v ~/.mpd/database
	yadm status
	yadm commit -m "$(date +'%Y-%m-%d %H:%M:%S')"
	yadm push
}
copyq_function(){
	if [ -n $1 ];then
		read -p "copyq? [y/n]:" ans
		if [ "$ans" = "y" ];then
			$echo ~/linux-custom-scripts/copyq_push.sh
		fi
	else
		$echo ~/linux-custom-scripts/copyq_push.sh
	fi
}
echo='echo'
echo=''
if [ -z $1 ];then
	$echo yadm_function
	$echo copyq_function ask
	$echo m_function
else
	case $1 in
		yadm|y) $echo yadm_function;;
		dotmin|m) $echo m_function;;
		copyq|cq) $echo copyq_function;;
		*) echo -e "Usage: $0 [arg]\narg:\n  yadm, y\tyadm funtion\n  dotmin, m\tdotfiles-minimal funtion\n  copyq, cq\texecute $l/copyq_push.sh"
	esac
fi
#f=()
