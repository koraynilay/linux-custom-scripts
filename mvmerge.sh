#!/bin/bash
#source="$1"
#target="$2"
#mdopts=""
#
#for a in $source/*;do
#	if [ -d "$a" ];then
#		mkdir $mdopts $target/"$i"
#		for b in "$a"/*;do
#			
#		done
#	fi
#done


# the one I used

out=""
echo='echo'
for a in *;do
	if [ -d "$a"/Videos ];then
		for b in "$a"/Videos/*;do
			if [ -d "$b" ];then
				$echo mkdir -vp $out/"$b"
				$echo mv -vi "$b"/* $out/"$b"
			else
				$echo mv -vi "$b" $out
			fi
		done
	fi
done
