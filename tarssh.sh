#!/bin/bash
outfilepath="$2"
server="$1"
files="${@:3}"
if ssh root@192.168.1.74 "[ -f $outfilepath ]";then
	echo file $outfilepath on $server already exists
	if [ $(read -p "Continue anyway? [y/n]") != "y" ];then
		echo "Aborted"
		exit 2
	fi
fi
#tar --acls --xattrs -cpvf - $files | ssh "$server" "cat - > '$outfilepath'"
#tar --acls --xattrs -cpvf - bck_C_fra_linux bck_ssd_C_pc_fra bck_ssd_F_pc_fra 2024-12-01_16-27-16.png | ssh root@192.168.1.74 'cat - > '
