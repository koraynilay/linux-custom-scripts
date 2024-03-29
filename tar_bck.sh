#!/bin/bash
export XZ_OPT='-T0 -0'
prefix=''
folders=("${prefix}/etc" "${prefix}/var" "${prefix}/root" "${prefix}/opt" "${prefix}/usr" "/efi")
exfolders=(${folders[@]} "${prefix}/swpfl.sys")
dest='/D/linux/tars'
#dest='/C'
topts='--one-file-system --acls --xattrs --preserve-permissions -c'
v=''
e=0
outtar=0
o='/dev/stdout'
tob=a
while getopts xvohzJf:p: opt;do
	case $opt in
		v)topts+="v";;
		o)outtar=1;;
		#?)echo -e "'$opt' Uknown option. Exiting"; exit 2;;
		h)	echo -ne "Usage: $0 [opt]\n";
			#echo -ne "  -n\t\tdon't be verbose (dont't print processed files)\n";
			echo -ne "  -v\t\tbe verbose (processed files)\n";
			echo -ne "  -o\t\toutput the tar output to $(eval echo ~$SUDO_USER)/tarbck_{folder_name}\n";
			echo -ne "  -z\t\tenables tar's -z option\n";
			echo -ne "  -J\t\tenables tar's -J option\n";
			echo -ne "  -x\t\toutput only the commands, don't execute them\n";
			echo -ne "  -p [prefix]\tFolder to use as the root folder (e.g. '/mnt' to backup '/mnt/usr', '/mnt/var', etc...)\n";
			echo -ne "  -f [a|r|s|h]\ta = all (all the root filesystem), r = root (like a, but without ${folders[@]}), s = slash (only ${folders[@]}), h = home (only the home folder)\n";
			exit 0;;
		x)e=1;;
		f)tob="$OPTARG";;
		p)prefix="$OPTARG";;
		z)	topts+="z";
			ext='.gz';;
		J)	topts+="J";
			ext='.xz';;
		?)exit 2;;
	esac
done
[[ $UID -ne 0 ]] && echo -e "This script needs root access. Exiting." && exit 1
if [ ! -d $dest ];then
	echo -n "$dest doesn't exists, create it? [y/n]:"
	read ans
	if [ "$ans" = "y" ];then
		mkdir -p "$dest"
	else
		exit 3
	fi
fi
#echo ${folders[@]}
#echo ${exfolders[@]}
fofs() {
	for ((i=0;i<${#folders[@]};i++)) do
		cf="${folders[i]}"
		fn="$(basename "${cf}")"
		if [ $outtar -eq 1 ];then
			o="$(eval echo ~$SUDO_USER)/tarbck_out_${fn}"
		fi
		echo $cf
		if [ $e -eq 1 ];then
			echo tar ${topts} -f "${dest}/${fn}.tar${ext}" "${cf}" \> $o
		else
			tar ${topts} -f "${dest}/${fn}.tar${ext}" "${cf}" > $o
			echo Sleeping 10 secs...
			sleep 10
		fi
	done
}
fofr() {
	exstring=""
	for ((i=0;i<${#exfolders[@]};i++)) do
		exstring+="--exclude=${exfolders[i]} "
	done
	if [ $outtar -eq 1 ];then
		o="$(eval echo ~$SUDO_USER)/tarbck_out_r"
	fi
	echo '/'
	if [ $e -eq 1 ];then
		echo tar ${exstring} ${topts} -f "${dest}/r.tar${ext}" "${prefix}/" \> $o
	else
		tar ${exstring} ${topts} -f "${dest}/r.tar${ext}" "${prefix}/" > $o
		echo Sleeping 10 secs...
		sleep 10
	fi
}
fofh() {
	if [ $outtar -eq 1 ];then
		o="$(eval echo ~$SUDO_USER)/tarbck_out_home"
	fi
	echo '/home'
	if [ $e -eq 1 ];then
		echo tar ${exstring} ${topts} -f "${dest}/home.tar${ext}" "${prefix}/home" \> $o
	else
		tar ${exstring} ${topts} -f "${dest}/home.tar${ext}" "${prefix}/home" > $o
		echo Sleeping 10 secs...
		sleep 10
	fi
	
}
case $tob in
	a)
		fofs
		fofr
		;;
	s)
		fofs
		;;
	r)
		fofr
		;;
	h)
		fofh
		;;
	*)
		echo "Invalid -f arg"
		exit 4
		;;
esac



#tar --one-file-system --exclude=/etc --exclude=/opt --exclude=/root --exclude=/usr --exclude=/var --exclude=/swpfl.sys --acls --xattrs -czpvf /D/linux/tars/r.tar.gz /
