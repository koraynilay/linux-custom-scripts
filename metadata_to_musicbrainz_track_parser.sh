#!/bin/sh
for a in *;do
	track="$(ffprobe "$a" 2>&1 | grep -P '[^a-zA-Z_]'track | awk '{print $NF}' | sed 's/\/0//g')"
	title="$(ffprobe "$a" 2>&1 | grep -P '[^a-zA-Z_]'title | cut -f2- -d':')"
	artist="$(ffprobe "$a" 2>&1 | grep -P '[^a-zA-Z_]'artist | cut -f2 -d':')"
	duration="$(ffprobe "$a" 2>&1 | grep Duration | cut -f2- -d':' | sed 's/\.[0-9][0-9].*//g' | tr -d ' ')"
	echo "$track.$title -$artist ($duration)"
done
