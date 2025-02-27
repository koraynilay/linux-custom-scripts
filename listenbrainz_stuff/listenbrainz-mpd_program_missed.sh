#!/bin/bash
. tag2filename.sh
. $HOME/.config/listenbrainz-mpd-from-logrc

file=$(<"$HOME/lblblblblb2")

jsons_to_submit=()
IFS=$'\n'
for song in $file; do
	IFS=' ' read -r datetime filename <<< $song
	lbjson=$(get_listenbrainz_json_mpd "$filename" "$datetime" "false" "false" "MPD" "listenbrainz-mpd (missed)")
	echo $lbjson | jq -c
	jsons_to_submit+=("$lbjson")
done

LISTENBRAINZ_IMPORT_DEBUG=1
LISTENBRAINZ_TOKEN="aa"
LISTENBRAINZ_TOKEN_FILE=""
LISTENBRAINZ_IMPORT_DRY=1
#listenbrainz_submit_import "${jsons_to_submit[@]}"

#payload="$(IFS=, ; echo "${jsons_to_submit[*]}")"
#echo "[$payload]"
