#!/bin/bash
. ./tag2filename.sh
. "$HOME/.config/listenbrainz-mpd-from-logrc"

mpd_log_file="$HOME/mpd_log_for_listenbrainz-v2"

jsons_to_submit=()
skipped_duration=()
skipped_error=()

to_add=$(<"$mpd_log_file")

IFS=$'\n'
i=0
for song in $to_add;do
	echo -ne "line $i\r"

	IFS=' ' read month day year time colon logger action filename <<< $song
	#echo $logger
	#echo $action

	# skip if not a played action
	# (unfortunately "player: played" is also used when restarting mpd)
	if [ "$logger" != "player:" ] && [ "$action" != "played" ];then
		#echo -ne "skipping: $song\r"
		continue
	fi

	filename=${filename#\"} # remove double quotes (") from around the filename
	filename=${filename%\"} # remove double quotes (") from around the filename

	datetime="$month $day $year $time"

	media_player="MPD"
	client="listenbrainz-mpd-from-log-v2.sh"
	listenbrainz_json="$(get_listenbrainz_json_mpd "$filename" "$datetime" "true" "false" "$media_player" "$client")"
	if [ $? -eq 2 ];then
		echo
		echo "error for '$song' ($filename), skipping"
		skipped_error+=("$i '$song' ($filename)")
		continue
	fi

	cur_ts="$(get_json_value "listened_at" "$listenbrainz_json")"
	halfduration="$(get_json_value "track_metadata.duration_ms" "$listenbrainz_json")"
	halfduration="$((halfduration / 2))"

	# save last timestamp
	# if current timestamp - last timestamp < halfduration
	# 	don't submit
	#
	# not much but better than assuming all "played" action are fully listened songs
	if [ $((cur_ts - last_ts)) -lt $halfduration ];then
		#echo "not enough duration '$song' ($filename), skipping"
		skipped_duration+=("$i '$song' ($filename)")
		continue
	fi
	last_ts=$cur_ts

	echo $listenbrainz_json | jq
	echo $filename
	jsons_to_submit+=("$listenbrainz_json")
	((i++))
done

echo

LISTENBRAINZ_IMPORT_DEBUG=1
LISTENBRAINZ_TOKEN="aa"
#LISTENBRAINZ_TOKEN_FILE=""
LISTENBRAINZ_IMPORT_DRY=1
#listenbrainz_submit_import "${jsons_to_submit[@]}"

IFS=$'\n'
if [ ${#skipped_duration[@]} -ne 0 ];then
	echo -n "${skipped_duration[*]}" > skipped_duration.txt
fi
if [ ${#skipped_error[@]} -ne 0 ];then
	echo -n "${skipped_error[*]}" > skipped_error.txt
fi
#if [ $sknl -ne 0 ];then
#	echo -n "${skipped_not_found[*]}" > skipped_not_found.txt
#fi

