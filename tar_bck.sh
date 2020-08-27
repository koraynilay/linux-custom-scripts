#!/bin/bash
folders=('/usr' '/var' '/opt' '/etc' '/root')
exfolders=(${folders[@]} '/swpfl.sys')
dest='/D/linux/tars'
topts='--one-file-system --acls --xattrs -czp'
v=''
e=0
outtar=0
o='/dev/stdout'
tob=a
while getopts xvohf: opt;do
	case $opt in
		v)v='-v';;
		o)outtar=1;;
		#?)echo -e "'$opt' Uknown option. Exiting"; exit 2;;
		h)	echo -ne "Usage: $0 [opt]\n";
			echo -ne "  -n\t\tdon't be verbose (dont't print processed files)\n";
			echo -ne "  -o\t\toutput the tar output to $(eval echo ~$SUDO_USER)/tarbck_{folder_name}\n";
			echo -ne "  -x\t\toutput only the commands, don't execute them\n";
			echo -ne "  -f [a|r|s]\ta = all (all the root filesystem), r = root (like a, but without ${folders[@]}), s = slash (only ${folders[@]})\n";
			exit 0;;
		x)e=1;;
		f)tob=$OPTARG;;
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
		if [ $outtar -eq 1 ];then
			o="$(eval echo ~$SUDO_USER)/tarbck_out_${cf/\/}"
		fi
		echo $cf
		if [ $e -eq 1 ];then
			echo tar ${topts} ${v} -f "${dest}/${cf/\/}.tar.gz" "${cf}" \> $o
		else
			tar ${topts} ${v} -f "${dest}/${cf/\/}.tar.gz" "${cf}" > $o
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
		echo tar ${exstring} ${topts} ${v} -f "${dest}/r.tar.gz" "/" \> $o
	else
		tar ${exstring} ${topts} ${v} -f "${dest}/r.tar.gz" "/" > $o
	fi
}
fofh() {
	if [ $outtar -eq 1 ];then
		o="$(eval echo ~$SUDO_USER)/tarbck_out_home"
	fi
	echo '/home'
	if [ $e -eq 1 ];then
		echo tar ${exstring} ${topts} ${v} -f "${dest}/home.tar.gz" "/home" \> $o
	else
		tar ${exstring} ${topts} ${v} -f "${dest}/home.tar.gz" "/home" > $o
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
