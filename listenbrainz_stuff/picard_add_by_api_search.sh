#!/bin/bash
#IFS=$'\n'
if [[ $1 = "-d" ]];then
	set -x
fi
for folder in "$@"; do
	v=$(grep -Po '(?<={).*(?=})' <<< "$folder")

	if [[ -z $v ]];then
		continue
	fi
	
	echo -n "adding $v to picard"
	key="catno"
	value="$v"
	query="$key:$value"
	mbid="$(curl --get --silent --data-urlencode "query=$query" https://musicbrainz.org/ws/2/release)"
	echo $mbid
	mbid="$(xq -r '.metadata."release-list".release."@id"' <<< "$mbid")"
	#echo "$mbid"
	curl http://127.0.0.1:8000/openalbum\?id\="$mbid"
	echo
	sleep 1
done
