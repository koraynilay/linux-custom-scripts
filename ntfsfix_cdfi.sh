filter_regex="/\/C|\/D|\/F|\/I/"
disks=$(lsblk --raw -o NAME,MOUNTPOINT,FSTYPE | awk "/sd[a-z][0-9]/ && \$2 ~ $filter_regex && \$3 ~ /ntfs/ {print \$1}")
mntpt=$(lsblk --raw -o NAME,MOUNTPOINT,FSTYPE | awk "/sd[a-z][0-9]/ && \$2 ~ $filter_regex && \$3 ~ /ntfs/ {print \$2}")
echo $disks
echo $mntpt
printf "Continue? [y/n]: "
read anc
if [ "$anc" = "y" ];then
	for mnt in $mntpt; do
		sudo umount -v $mnt
		if [ $? -ne 0 ];then
			printf "Error occured unmounting $mnt, continue anyway? [y/n]: "
			read an
			if [ "$an" != "y" ];then
				exit 1
			fi
		fi
	done
	for hd in $disks; do
		#sudo umount /dev/$hd
		sudo ntfsfix /dev/$hd
	done
	printf "Remount all disks in /etc/fstab? [y/n]: "
	read ans
	if [ "$ans" = "y" ];then
		sudo mount -va
	fi
fi
