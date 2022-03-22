#!/bin/bash
echo='echo'
#pwd
# $1 parent dir of filename {//}
# $2 filename only (basename of file) {/}
# $3 path (from current position) {}
# $4 password for the archive(s)
OFS=$IFS
IFS='/'
ff=($1)
folder="../Musica_base64"
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

filename=$(echo -n $2 | base32 -w0)
$echo 7z a -t7z -p"$4" -mx=0 $folder/$filename "$3"
