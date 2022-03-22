#!/bin/bash
echo=''
echo
echo $PWD $@
#pwd
# $1 parent dir of filename (fd: {//})
# $2 filename only (basename of file) (fd: {/})
# $3 path (from current position) (fd: {})
# $4 password for the archive(s)
OFS=$IFS
IFS='/'
ff=($1)
folder="../Musica_base32"
for i in "${ff[@]}";do
	#echo $i
	i=$(echo -n $i | base32 -w0)
	#echo $i
	folder+="/"
	folder+="$i"
done
IFS=$OFS
echo $folder
$echo mkdir -pv $folder

echo $folder/$filename.7z
filename=$(echo -n $2 | base32 -w0)
if ! [ -e $folder/$filename.7z ];then
	$echo 7z a -t7z -p"$4" -mx=0 $folder/$filename.7z "$3"
fi
echo
