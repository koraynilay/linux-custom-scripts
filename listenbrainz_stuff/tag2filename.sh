#!/bin/bash
shopt -s expand_aliases
alias jq='jq -r' # needed to remove quotes from json
alias json_metadata_cmd='ffprobe -v quiet -show_format -of json'
file="$HOME/playback_reporting.db.sql_output.json"

artist=$(jq '.[0].ItemName' < $file | awk 'BEGIN {FS=" - "} {print $1}')
title=$(jq '.[0].ItemName' < $file | awk 'BEGIN {FS=" - "} {print $2}')
echo $artist
echo $title
echo $album

eval $(awk 'BEGIN { FS=" - "; q="\"" }
	{
		match($2, /(.*) \((.*)\)/, ta);
		print "artist="q $1 q;
		print  "title="q ta[1] q;
		print  "album="q ta[2] q;
	}' <(jq '.[0].ItemName' < $file))
echo $artist
echo $title
echo $album
