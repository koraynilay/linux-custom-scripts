#!/bin/bash
. ./tag2filename.sh
. "$HOME/.config/listenbrainz-mpd-from-logrc"

mpd_log_file="$HOME/mpd_log_for_listenbrainz-v2"

jsons_to_submit=()
skipped_duration=()
skipped_error=()
skipped_noartist=()
skipped_notitle=()
skipped_not_found=()
declare -A json_cache

to_add=$(<"$mpd_log_file")
#to_add="Nov 28 2019 21:51 : player: played \"Megalovania - An Instrumental Version of Retro Gaming's REVENGE (Megalovania Remix).mp3\""

IFS=$'\n'
i=0
for song in $to_add;do
	#echo -ne "line $i\r"
	echo -e "line $i"

	if [ "$i" -eq 10000 ];then
		exit
	fi

#	if [ "$i" -eq 910 ];then
#		exit
#	fi
#
#	if [ "$i" -lt 908 ];then
#		((i++))
#		continue
#	fi

#	if [ "$i" -eq 908 ];then
#		set -x
#	fi
#	if [ "$i" -eq 9010 ];then
#		set +x
#	fi

	IFS=' ' read month day year time colon logger action filename <<< $song
	#echo $logger
	#echo $action

	# skip if not a played action
	# (unfortunately "player: played" is also used when restarting mpd)
	if [ "$logger" != "player:" ] && [ "$action" != "played" ];then
		#echo -ne "skipping: $song\r"
		((i++))
		continue
	fi

	filename=${filename#\"} # remove double quotes (") from around the filename
	filename=${filename%\"} # remove double quotes (") from around the filename

	datetime="$month $day $year $time"

	if [ -z "${json_cache[$filename]}" ];then

		media_player="MPD"
		client="listenbrainz-mpd-from-log-v2.sh"
		#listenbrainz_json="$(get_listenbrainz_json "$MPD_MUSIC_DIR/$filename" "$datetime" "true" "false" "$media_player" "$client")"
		#listenbrainz_json="$(get_listenbrainz_json_mpd "$filename" "$datetime" "true" "false" "$media_player" "$client")"
		track_metadata="$(get_almost_listenbrainz_json_mpd "$filename" "$media_player" "$client")"
		exitcode=$?
		if [ $exitcode -eq 1 ];then
			#echo "no artist for '$song' ($filename), skipping"
			skipped_noartist+=("$i '$song' ($filename)")
			((i++))
			continue
		elif [ $exitcode -eq 2 ];then
			#echo "no title for '$song' ($filename), skipping"
			skipped_notitle+=("$i '$song' ($filename)")
			((i++))
			continue
		elif [ $exitcode -eq 249 ];then
			#echo "not found '$song' ($filename), skipping"
			skipped_not_found+=("$i '$song' ($filename)")
			((i++))
			continue
		fi

		echo $track_metadata | jq -c
		json_cache[$filename]="$track_metadata"
	else
		track_metadata="${json_cache["$filename"]}"
	fi

	cur_ts="$(date -d "$datetime" +%s)"
	halfduration="$(get_json_value "additional_info\"][\"duration_ms" "$track_metadata")"
	halfduration="$((halfduration / 2 / 1000))"

	# save last timestamp
	# if current timestamp - last timestamp < halfduration
	# 	don't submit
	#
	# not much but better than assuming all "played" action are fully listened songs
	#set -x
	sub=$((cur_ts - last_ts))
	last_ts=$cur_ts
	if [ $sub -lt $halfduration ];then
		#set +x
		#echo "not enough duration '$song' ($filename), skipping"
		skipped_duration+=("$i '$song' ($filename)")
		((i++))
		continue
	fi
	#set +x

	listenbrainz_json="
	{
	  \"listened_at\": $cur_ts,
	  \"track_metadata\": $track_metadata
	}
	";

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
if [ ${#skipped_noartist[@]} -ne 0 ];then
	echo -n "${skipped_noartist[*]}" > skipped_noartist.txt
fi
if [ ${#skipped_notitle[@]} -ne 0 ];then
	echo -n "${skipped_notitle[*]}" > skipped_notitle.txt
fi
if [ ${#skipped_not_found[@]} -ne 0 ];then
	echo -n "${skipped_not_found[*]}" > skipped_not_found.txt
fi
touch json_cache.txt
for x in "${!json_cache[@]}"; do
	printf "%s=%s\n" "$x" "${json_cache[$x]}" >> json_cache.txt
done
