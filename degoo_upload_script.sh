#!/bin/bash
echo=0;
foldername="`basename $PWD`_degoo";
if [ $echo -eq 1 ];then
	echo="echo";
else
	echo="";
fi
for a in *; do
	$echo mkdir -p "${foldername}/${a}.folder";
	$echo split --verbose -b 500M -d -a 3 "$a" "${foldername}/${a}.folder/${a}.";
done
