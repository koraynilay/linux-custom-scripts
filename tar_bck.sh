#!/bin/bash
[[ $UID -ne 0 ]] && echo -e "This script needs root access. Exiting." && exit 1
folders=('/usr' '/var' '/opt' '/etc' '/root')
exfolders=(${folders[@]} '/swpfl.sys')
dest='/D/linux/tars'
topts='--acls --xattrs -czpf'
v='-v'
outtar=0
while getopts noh opt;do
	case $opt in
		n)v='';;
		o)outtar=1;;
		#?)echo -e "'$opt' Uknown option. Exiting"; exit 2;;
		h)	echo -ne "Usage: $0 [opt]\n";
			echo -ne "  -n\tdon't be verbose (dont't print processed files)\n";
			echo -ne "  -o\toutput the tar output to $(eval echo ~$SUDO_USER)/tarbck_{folder_name}\n";
			exit 0;;
		?)exit 2;;
	esac
done
#echo ${folders[@]}
#echo ${exfolders[@]}
for ((i=0;i<${#folders[@]};i++)) do
	cf="${folders[i]}"
	if [ $outtar -eq 1 ];then
		o="> $(eval echo ~$SUDO_USER)/tarbck_out_${cf/\/}"
	fi
	echo tar ${topts} ${v} ${dest}/${cf/\/}.tar.gz ${cf} ${o}
done




#tar --one-file-system --exclude=/etc --exclude=/opt --exclude=/root --exclude=/usr --exclude=/var --exclude=/swpfl.sys --acls --xattrs -czpvf /D/linux/tars/r.tar.gz /
