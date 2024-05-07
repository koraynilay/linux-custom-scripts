#!/bin/bash
. ./tag2filename.sh

mdir="$HOME/lns/music_ntfs"
shopt -s expand_aliases
alias jq='jq -r' # needed to remove quotes from json
alias json_metadata_cmd='ffprobe -v quiet -show_format -of json'
file="$HOME/jellyfin_listenbrainz/playback_reporting.db.sql_output_edited.json"

len=$(jq ". | length" < $file)
for i in `seq 120 121`;do
#for i in `seq 0 $len`;do
	json=$(jq ".[$i]" < $file)

	#echo -ne "$i\r"

	itemtype=$(get_json_value 'ItemType' "$json")
	if [ "$itemtype" != "Audio" ];then
		echo "$i"
		continue
	fi

	echo -ne "$i"

	itemname=$(get_json_value 'ItemName' "$json")
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
	#echo -n " "$filename

	song_json=$(info_func "$mdir/$filename" ".format")
	tags_json=$(get_json_value "tags" "$song_json")

	duration=$(get_json_value "duration" "$song_json")
	duration=$(calc -p "round($duration * 1000)") # duration is ms (as int)
	halfduration=$(calc -p "round($duration / 2000)")

	playduration=$(get_json_value "PlayDuration" "$json")

	echo -n " "$playduration $halfduration $duration
	
	if [ "$playduration" -ge "$halfduration" ];then
		echo -n " curl"
	fi

	echo

	artist=""
	title=""
	album=""
done
