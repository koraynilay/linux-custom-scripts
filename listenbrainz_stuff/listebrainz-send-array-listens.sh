#!/bin/bash
. tag2filename.sh
. $HOME/.config/listenbrainz-mpd-from-logrc

jsons=()
IFS=$'\n'
for line in $(cat $HOME/tses);do
	ts=$(cut -d' ' -f1 <<< "$line")
	title=$(cut -d' ' -f2- <<< "$line")
	echo $ts $title
	fname=$(mpc find title "$title")
	json=$(get_listenbrainz_json $MPD_MUSIC_DIR/"$fname" "$ts" "false" "true" "Gelli (Jellyfin) on XQ-BT52" "listebrainz-send-array-listens.sh")
	jsons+=("$json")
done

#LISTENBRAINZ_IMPORT_DEBUG=1
#LISTENBRAINZ_TOKEN="aa"
#LISTENBRAINZ_TOKEN_FILE=""
#LISTENBRAINZ_IMPORT_DRY=1
listenbrainz_submit_import "${jsons[@]}"
