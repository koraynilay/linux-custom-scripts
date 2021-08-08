#!/bin/sh
date_format="$2"
date_format=""
time=`getfattr --only-values -n system.ntfs_crtime_be "$1" 2>/dev/null | perl -MPOSIX -0777 -ne '$t = unpack("Q>"); print $t/10000000-11644473600'`
#epoch=`echo -n $a | perl -MPOSIX -0777 -ne '$t = unpack("Q>"); print $t/10000000-11644473600'`
#date --date="@$epoch"
echo -ne "$(date --date="@$time" $date_format)\t"
echo $1

#time=`getfattr --only-values -n system.ntfs_crtime_be $@`
#for a in $time;do
#	echo -n $a | perl -MPOSIX -0777 -ne '$t = unpack("Q>"); print $t/10000000-11644473600'
#done
