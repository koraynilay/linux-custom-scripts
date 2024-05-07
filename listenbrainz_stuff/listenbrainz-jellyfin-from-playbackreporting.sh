#!/bin/bash
. ./tag2filename.sh

mdir="$HOME/lns/music_ntfs"
shopt -s expand_aliases
alias jq='jq -r' # needed to remove quotes from json
alias json_metadata_cmd='ffprobe -v quiet -show_format -of json'
file="$HOME/jellyfin_listenbrainz/playback_reporting.db.sql_output_edited.json"

len=$(jq ". | length" < $file)
#for i in `seq 279 279`;do
for i in `seq 0 $len`;do
	json=$(jq ".[$i]" < $file)

	echo -ne "$i\r"
	sleep 0.05

	itemtype=$(get_json_field '.ItemType' "$json")
	if [ "$itemtype" != "Audio" ];then
		continue
	fi
	itemname=$(get_json_field '.ItemName' "$json")
	eval $(perl -ne '/^([^-]*(?:[^ ]* -[^ ]|[^ ]- [^ ]*|[^ ]*[^ ]-[^ ][^ ]*)*[^-]*)(?-1)* - (.*) \(((?:[^()]*\([^()]*\)[^()]*)|(?:[^()]*))\)$/;
			print "artist=\"".($1 =~ s/"/\\"/rg)."\"\n";
			print  "title=\"".($2 =~ s/"/\\"/rg)."\"\n";
			print  "album=\"".($3 =~ s/"/\\"/rg)."\"\n";' <<< "$itemname")
	if [ "$artist" = "Not Known" ] || [ "$artist" = "Artista sconosciuto" ];then
		artist=""
	fi
	if [ "$album" = "Not Known" ] || [ "$album" = "Album sconosciuto" ];then
		album=""
	fi

	#echo at:$artist tt:$title ab:$album tn:$tracknumber rmbid:$recording_mbid
	filename=$(get_filename_from_tags_mpd "$artist" "$title" "$album" "$tracknumber" "$recording_mbid")
	if [ -z "$filename" ];then
		echo [$i] at:$artist tt:$title ab:$album tn:$tracknumber rmbid:$recording_mbid
		#echo $json | jq
		#echo $itemname
#	else
#		echo [$i] at:$artist tt:$title ab:$album tn:$tracknumber rmbid:$recording_mbid
#		echo $filename
	fi
	echo $filename

	song_json=$(info_cmd "$filename" ".format")
	tags_json=$(get_json_field ".tags" "$song_json")

	duration=$(get_json_field ".duration" "$song_json")

	playduration=$(get_json_field '.PlayDuration' "$json")
	echo $playduration

	artist=""
	title=""
	album=""
done
