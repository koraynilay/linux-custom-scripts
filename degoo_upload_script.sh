#!/bin/bash
echo pwd:`pwd`. Are you sure?
echo=1;
read res
if [ "$res" == "yes" ]; then
	echo=0;
fi
foldername="`basename "$PWD"`_degoo";
if [ $echo -eq 1 ];then
	echo="echo";
else
	echo="";
fi
for a in *; do
	$echo mkdir -vp "${foldername}/${a}.folder";
	$echo split --verbose -b 500M -d -a 3 "$a" "${foldername}/${a}.folder/${a}.";
done
