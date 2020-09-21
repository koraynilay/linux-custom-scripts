#!/bin/sh
pkg_list() {
	printf "#" > $HOME/pkglist.txt
	printf "#" > $HOME/pkglist_aur.txt
	date >> $HOME/pkglist.txt
	date >> $HOME/pkglist_aur.txt
	printf "\n" >> $HOME/pkglist.txt
	printf "\n" >> $HOME/pkglist_aur.txt
	pacman -Qqen >> $HOME/pkglist.txt
	pacman -Qqem >> $HOME/pkglist_aur.txt
}


pkg_list
yadm status
sleep 1
yadm add -u
yadm commit -m "$(date +'%Y-%m-%d %H:%M:%S')"
yadm push
#f=()
