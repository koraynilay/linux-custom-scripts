#!/bin/sh
date_format=""
time=`getfattr --only-values -n system.ntfs_crtime_be "$1" | perl -MPOSIX -0777 -ne '$t = unpack("Q>"); print $t/10000000-11644473600'`
#epoch=`echo -n $a | perl -MPOSIX -0777 -ne '$t = unpack("Q>"); print $t/10000000-11644473600'`
#date --date="@$epoch"
date --date="@$time" $date_format

#time=`getfattr --only-values -n system.ntfs_crtime_be $@`
#for a in $time;do
#	echo -n $a | perl -MPOSIX -0777 -ne '$t = unpack("Q>"); print $t/10000000-11644473600'
#done
