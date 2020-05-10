printf "#" > pkglist.txt
printf "#" > pkglist_aur.txt
date >> pkglist.txt
date >> pkglist_aur.txt
printf "\n" >> pkglist.txt
printf "\n" >> pkglist_aur.txt
pacman -Qqen >> pkglist.txt
pacman -Qqem >> pkglist_aur.txt
yadm status
sleep 3
yadm add -u
yadm commit -m "$(date +'%Y-%m-%d %H:%M:%S')"
yadm push
