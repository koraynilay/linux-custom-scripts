#!/bin/bash
. ./tag2filename.sh

mdir="$HOME/lns/music_ntfs"
shopt -s expand_aliases
alias jq='jq -r' # needed to remove quotes from json
alias json_metadata_cmd='ffprobe -v quiet -show_format -of json'
file="$HOME/jellyfin_listenbrainz/playback_reporting.db.sql_output_edited.json"

len=$(jq ". | length" < $file)
for i in `seq 0 100`;do
#for i in `seq 0 $len`;do
	json=$(jq ".[$i]" < $file)

	itemname=$(jq '.ItemName // empty' <<< $json)
	eval $(awk 'BEGIN { q="\"" }
		{
			match($0, /^([^-]*) - (.*) \((.*)\)$/, ta);
			print "artist="q ta[1] q;
			print  "title="q ta[2] q;
			print  "album="q ta[3] q;
		}' <<< $itemname)
	if [ "$artist" = "Not Known" ] || [ "$artist" = "Artista sconosciuto" ];then
		artist=""
	fi
	if [ "$album" = "Not Known" ] || [ "$album" = "Album sconosciuto" ];then
		album=""
	fi

	echo at:$artist tt:$title ab:$album tn:$tracknumber rmbid:$recording_mbid
	filename=$(get_filename_from_tags_mpd "$artist" "$title" "$album" "$tracknumber" "$recording_mbid")
	echo $filename

	artist=""
	title=""
	album=""
done

#playduration=$(jq '.PlayDuration // empty' <<< $json)
#echo $playduration
