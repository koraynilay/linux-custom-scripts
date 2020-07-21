filter_regex="/\/C|\/D|\/F|\/I/"
disks=$(lsblk --raw -o NAME,MOUNTPOINT,FSTYPE | awk "/sd[a-z][0-9]/ && \$2 ~ $filter_regex && \$3 ~ /ntfs/ {print \$1}")
mntpt=$(lsblk --raw -o NAME,MOUNTPOINT,FSTYPE | awk "/sd[a-z][0-9]/ && \$2 ~ $filter_regex && \$3 ~ /ntfs/ {print \$2}")
echo $disks
for mnt in $mntpt; do
	sudo umount $mnt
done
for hd in $disks; do
	#sudo umount /dev/$hd
	sudo ntfsfix /dev/$hd
done
printf "Remount all disks in /etc/fstab? [y/n]: "
read ans
if [ "$ans" = "y" ];then
	sudo mount -a
fi
