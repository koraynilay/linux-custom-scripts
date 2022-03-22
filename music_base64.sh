#!/bin/bash
echo='echo'
echo $PWD
# $1 parent dir of filename {//}
# $2 filename only (basename of file) {/}
# $3 path (from current position) {}
folder="$1"
OFS=$IFS
IFS='/'
for i in $folder;do
	echo $i
done
$echo mkdir -pv ../Musica_base64/$(echo $1 | base64)
$echo 7z a -t7z -mx=0 ../Musica_base64/$(echo $1 | base64) "$3"
