#!/bin/sh
[[ $UID -ne 0 ]] && echo -e "This script needs root access. Exiting." && exit 1
folders=('/usr' '/var' '/opt' '/etc' '/root')
exfolders=(${folders[@]} '/swpfl.sys')
dest='/D/linux/tars'
topts='--acls --xattrs -czpvf'
#echo ${folders[@]}
#echo ${exfolders[@]}
for ((i=0;i<${#folders[@]};i++)) do
	echo tar ${topts} ${dest}/${folders[i]/\/}.tar.gz ${folders[i]}
done




#tar --one-file-system --exclude=/etc --exclude=/opt --exclude=/root --exclude=/usr --exclude=/var --exclude=/swpfl.sys --acls --xattrs -czpvf /D/linux/tars/r.tar.gz /
