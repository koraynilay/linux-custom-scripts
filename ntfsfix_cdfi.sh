filter_regex="/\/C|\/D|\/F|\/I/"
disks=$(lsblk --raw -o NAME,MOUNTPOINT,FSTYPE | awk "/sd[a-z][0-9]/ && \$2 ~ $filter_regex && \$3 ~ /ntfs/ {print \$1}")
echo $disks
for hd in $disks; do
	sudo ntfsfix /dev/$hd
done
