#!/bin/sh
OFS=$IFS
ask() {
	echo -en $1 [y/n]:
	read ans
	if [ "$ans" = "y" ];then
		return 0
	fi
	return 1
}
IFS=$'\n'
pkgs=$(expac "%m %n" -l'\n' -Q -H M $target | sed s/MiB//g | sort -nr)
for pkg in $pkgs;do
	pkg_name=$(echo $pkg | awk '{print $2}')
	pkg_size=$(echo $pkg | awk '{print $1}')
	printf "%5b\t%b\t%-30b\t%s " $pkg_size MiB $pkg_name 'info?'
	ask && pacman -Qi $pkg_name && ask "remove $pkg_name ($pkg_size)?" && sudo pacman -Rns $pkg_name
done
