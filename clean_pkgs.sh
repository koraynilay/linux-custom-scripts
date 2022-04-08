#!/bin/sh
ask() {
	echo -en $1 [y/n]:
	read ans
	if [ "$ans" = "y" ];then
		return 0
	fi
	return 1
}
pkgs=$(expac "%m %n" -l'\n' -Q -H M $target | sed s/MiB//g | sort -nr)
for pkg in $pkgs;do
	#pkg_name=$(echo $pkg | awk '{print $2}') #only if IFS is \n
	#pkg_size=$(echo $pkg | awk '{print $1}')
	#ask "$pkg_size\t$pkg_name\t\t\tinfo?" && pacman -Qi $pkg && ask "remove $pkg?" && sudo pacman -Rns $pkg
	ask "$pkg\t$pkg\t\t\tinfo?" && pacman -Qi $pkg && ask "remove $pkg?" && sudo pacman -Rns $pkg
done
