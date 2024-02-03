#!/bin/sh
for a in *;do
	track="$(ffprobe "$a" 2>&1 | grep --ignore-case -P '[^a-zA-Z_]\strack' | awk '{print $NF}' | sed 's/\/0//g')"
	title="$(ffprobe "$a" 2>&1 | grep --ignore-case -P '[^a-zA-Z_]\stitle' | cut -f2- -d':')"
	artist="$(ffprobe "$a" 2>&1 | grep --ignore-case -P '[^a-zA-Z_]\sartist' | cut -f2 -d':')"
	duration="$(ffprobe "$a" 2>&1 | grep --ignore-case duration | cut -f2- -d':' | sed 's/\.[0-9][0-9].*//g' | tr -d ' ')"
	echo "$track.$title -$artist ($duration)"
done
