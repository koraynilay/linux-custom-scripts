#!/bin/sh
print_usage(){
	printf "Usage: $0 [options]\n"
	printf "  -a\tactivate chroot with specified parameters\n"
	printf "  -c\tcreate chroot with the other options\n"
	printf "  -n\tnew root (absolute path) $needcreactiv\n"
	printf "  -m\tmount point for the root (absolute path) $needcreactiv\n"
	printf "  -f\tlist of absolute paths of files/folders to copy (\"'/path/to/file1' '/path/to/file2'\", so that they're a single argument)\n"
	printf "  -p\tlist of packages to install\n"
	printf "  -s\tscript to execute right after creation of the chroot\n"
	printf "  -v\tprint variables\n"
	printf "  -h\tshow this help\n"
}
verbose=0
while getopts n:m:f:r:p:u:z:s:cahv option;do
	case $option in
		v)verbose=1;;
		n)newrt=$OPTARG;;
		m)mntrt=$OPTARG;;
		p)pkgs=$OPTARG;;
		s)script=$OPTARG;;
		f)ftcopy=$OPTARG;;
		h)print_usage;exit 0;;
		?)exit 1;;
	esac
done
[[ -z $1 ]] && print_usage && exit 3
[[ $UID -ne 0 ]] && printf "This script needs root privileges.\n" && exit 5
pkgs=${pkgs:=('git' 'vim' 'zsh' 'which' 'sudo')}
pkgs=${pkgs#\(}
pkgs=${pkgs%\)}
if [ $verbose -eq 1 ];then
	echo $newrt
	echo $mntrt
	echo $homef
	echo $rootf
	echo $pkgs
	echo $usernr
	printf "5 seconds timeout, press Control-C to cancel the whole script\n"
	sleep 5
fi
if [ ! -d $newrt ];then
	printf "New root folder doesn't exist, create it [y/n]? "
	read ans
	if [ "$ans" = "y" ];then
		mkdir -p $newrt
	else
	       exit 2
	fi
fi
if [ ! -d $mntrt ];then
	printf "New mount folder doesn't exist, create it [y/n]? "
	read ans
	if [ "$ans" = "y" ];then
		mkdir -p $mntrt
	else
		exit 2
	fi
fi
pacstrap $newrt base $pkgs

cp -vr "/usr/share/terminfo" "$newrt/usr/share/"
if [ -n $ftcopy ];then
	for file in $ftcopy;do
		[[ $verbose -eq 1 ]] && echo $file;
		cp -vr $file "$newrt/$file"
	done
fi
mount --bind $newrt $mntrt
if [ -n $script ];then
	cp -vr "$script" "$newrt/"
	arch-chroot $mntrt "/bin/bash" -c "./$(basename $script)"
else
	arch-chroot $mntrt
fi
