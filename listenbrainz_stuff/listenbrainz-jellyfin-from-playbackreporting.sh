#!/bin/bash
. ./tag2filename.sh
. $HOME/.config/listenbrainz-mpd-from-logrc

mdir="$HOME/lns/music_ntfs"
#file="$HOME/jellyfin_listenbrainz/playback_reporting.db.sql_output_edited.json"
file="$HOME/jellyfin_listenbrainz/playback_reporting.db.sql_output_2.json"

jsons_to_submit=()
skipped_duration=()
skipped_noaudio=()
skipped_error=()
skipped_not_found=()

len=$(jq ". | length" < $file)
#for i in `seq 187 187`;do
#for i in `seq 400 $len`;do
#for i in `seq 181 181`;do
for i in `seq 0 $len`;do
	json=$(jq ".[$i]" < $file)

	jtsl="${#jsons_to_submit[@]}"
	skdl="${#skipped_duration[@]}"
	skal="${#skipped_noaudio[@]}"
	skel="${#skipped_error[@]}"
	sknl="${#skipped_not_found[@]}"
	vald=$(( jtsl + skdl + skal + skel + sknl == i ))
	if [ $vald -eq 1 ];then
		vald="yee"
	else
		vald="noo"
	fi
	echo -ne "[$i]($vald); added: $jtsl; skipped playduration: $skdl; skipped no audio: $skal; skipped error: $skel; skipped not found: $sknl\r"

	itemtype=$(get_json_value 'ItemType' "$json")
	if [ "$itemtype" != "Audio" ];then
		#echo "$i no Audio"
		skipped_noaudio+=("$i")
		continue
	fi

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
	filename=$(get_filename_from_tags_mpd "$artist" "$title" "$album" "$tracknumber" "$recording_mbid" | head -1)
	if [ -z "$filename" ];then
		echo "[$i] not found $i (artist '$artist' title '$title' album '$album' track '$tracknumber' MUSICBRAINZ_TRACKID '$recording_mbid')"
		skipped_not_found+=("$i artist '$artist' title '$title' album '$album' track '$tracknumber' MUSICBRAINZ_TRACKID '$recording_mbid'")
		continue
	fi
	#echo -n " "$filename

	song_json="$(info_func "$mdir/$filename" ".format")"

	duration="$(get_json_value "duration" "$song_json")"
	duration="$(calc -p "round($duration * 1000)")" # duration is ms (as int)
	halfduration="$(calc -p "round($duration / 2000)")"

	playduration="$(get_json_value "PlayDuration" "$json")"

	#echo -n " "$playduration $halfduration $duration
	
	if [ "$playduration" -lt "$halfduration" ];then
		#echo "skipping because playduration ($playduration) < half of the duration ($halfduration)"
		skipped_duration+=("$i '$filename'")
		continue
	fi

	datetime="$(get_json_value "DateCreated" "$json")"

	client="$(get_json_value "ClientName" "$json")"
	device="$(get_json_value "DeviceName" "$json")"

	media_player="$client (Jellyfin) on $device"

	listenbrainz_json="$(get_listenbrainz_json "$mdir/$filename" "$datetime" "false" "$media_player" "listenbrainz-jellyfin-from-playbackreporting.sh")"

	if [ $? -eq 2 ];then
		echo
		echo "error in $i ($filename), skipping"
		skipped_error+=("$i")
		continue
	fi

	#echo $listenbrainz_json
	jsons_to_submit+=("$listenbrainz_json")

	artist=""
	title=""
	album=""
done

LISTENBRAINZ_IMPORT_DEBUG=1
#LISTENBRAINZ_TOKEN="aa"
#LISTENBRAINZ_TOKEN_FILE=""
#LISTENBRAINZ_IMPORT_DRY=1
listenbrainz_submit_import "${jsons_to_submit[@]}"

IFS=$'\n'
if [ $skdl -ne 0 ];then
	echo -n "${skipped_duration[*]}" > skipped_duration.txt
fi
if [ $skal -ne 0 ];then
	echo -n "${skipped_noaudio[*]}" > skipped_noaudio.txt
fi
if [ $skel -ne 0 ];then
	echo -n "${skipped_error[*]}" > skipped_error.txt
fi
if [ $sknl -ne 0 ];then
	echo -n "${skipped_not_found[*]}" > skipped_not_found.txt
fi
