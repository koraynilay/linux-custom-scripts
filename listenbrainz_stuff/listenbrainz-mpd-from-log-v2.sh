#!/bin/bash
. ./tag2filename.sh
. "$HOME/.config/listenbrainz-mpd-from-logrc"

#mpd_log_file="$HOME/mpd_log_for_listenbrainz-v2"
mpd_log_file="$HOME/mpd_log_for_listenbrainz-v2-epoch"
mpd_log_file_length=$(wc -l "$mpd_log_file")

jsons_to_submit=()
skipped_duration=()
skipped_error=()
skipped_noartist=()
skipped_notitle=()
skipped_not_found=()
json_cache_file="json_cache.txt"
if [ -f "$json_cache_file" ];then
	. "$json_cache_file"
else
	declare -A json_cache
fi
json_duration_cache_file="json_duration_cache.txt"
if [ -f "$json_duration_cache_file" ];then
	. "$json_duration_cache_file"
else
	declare -A json_duration_cache
fi
json_halfduration_cache_file="json_halfduration_cache.txt"
if [ -f "$json_halfduration_cache_file" ];then
	. "$json_halfduration_cache_file"
else
	declare -A json_halfduration_cache
fi
#for x in "${!json_cache[@]}"; do
#	echo $x
#	echo ${json_cache[$x]} | jq
#	if [ "$?" -ne 0 ];then
#		exit $?
#	fi
#done
#exit

to_add=$(<"$mpd_log_file")
#to_add="Nov 28 2019 21:51 : player: played \"Megalovania - An Instrumental Version of Retro Gaming's REVENGE (Megalovania Remix).mp3\""

#UPLINE=$(tput cuu1)
#ERASELINE=$(tput el)

IFS=$'\n'
i=0
skipped_noplayer=0
use_epoch_log=1
for song in $to_add;do
	jtsl="${#jsons_to_submit[@]}"
	skdl="${#skipped_duration[@]}"
	skpl=$skipped_noplayer
	skal="${#skipped_noartist[@]}"
	sktl="${#skipped_notitle[@]}"
	skel="${#skipped_error[@]}"
	sknl="${#skipped_not_found[@]}"
	vald=$(( jtsl + skdl + skpl + skal + stkl + skel + sknl == i ))
	if [ $vald -eq 1 ];then
		vald="yee"
	else
		vald="noo"
	fi
	#echo "line $i ($vald); added: $jtsl; skipped playduration: $skdl; skipped no player: $skpl;"
	#echo "skipped no artist: $skal; skipped error: $skel; skipped not found: $sknl;"
	echo -ne "line $i ($vald); added: $jtsl; skipped: playduration: $skdl; no player: $skpl; no artist: $skal; no title: $sktl; error: $skel; not found: $sknl;\r"


#	if [ "$i" -eq 2000 ];then
#		echo
#		exit
#	fi

#	if [ "$i" -eq 2175 ];then
#		exit
#	fi

#	if [ "$i" -lt 2170 ];then
#		((i++))
#		continue
#	fi

#	if [ "$i" -eq 19 ];then
#		set +x
#	fi
#	if [ "$i" -eq 18 ];then
#		echo
#		set -x
#		echo $song
#	fi

	if [ "$use_epoch_log" -eq 1 ];then
		IFS=' ' read -r datetime colon logger action filename <<< $song
	else
		IFS=' ' read -r month day year time colon logger action filename <<< $song
		datetime="$month $day $year $time"
	fi
	#echo $logger
	#echo $action

	# skip if not a played action
	# (unfortunately "player: played" is also used when restarting mpd)
	if [ "$logger" != "player:" ] && [ "$action" != "played" ];then
		#echo -ne "skipping: $song\r"
		((skipped_noplayer++))
		((i++))
		continue
	fi

	filename=${filename#\"} # remove double quotes (") from around the filename
	filename=${filename%\"} # remove double quotes (") from around the filename

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
		track_metadata="${json_cache[$filename]}"
	fi

	if [ -z "${json_halfduration_cache[$filename]}" ];then
		halfduration="${json_halfduration_cache[$filename]}"
	else
		halfduration="$(get_json_value "additional_info\"][\"duration_ms" "$track_metadata")"
		halfduration="$((halfduration / 2 / 1000))"
	fi

	if [ "$use_epoch_log" -eq 1 ];then
		cur_ts=$datetime
	else
		cur_ts="$(date -d "$datetime" +%s)"
	fi

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

	#echo -n "$UPLINE$ERASELINE$UPLINE$ERASELINE"

	#echo $listenbrainz_json | jq
	#echo $filename
	jsons_to_submit+=("$listenbrainz_json")
	((i++))
done

echo

LISTENBRAINZ_IMPORT_DEBUG=1
LISTENBRAINZ_TOKEN="aa"
#LISTENBRAINZ_TOKEN_FILE=""
LISTENBRAINZ_IMPORT_DRY=1
#listenbrainz_submit_import "${jsons_to_submit[@]}"
payload="$(IFS=, ; echo "${jsons_to_submit[*]}")"
echo "[$payload]" > to_sub.json

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
if ! [ -f "json_cache.txt" ];then
	echo "writing to $json_cache_file"
	printf '#!/bin/bash\ndeclare -A json_cache\n' > "$json_cache_file"
	for x in "${!json_cache[@]}"; do
		printf 'json_cache[%s]="%s"\n' "$x" "${json_cache[$x]}" >> "$json_cache_file"
		echo -e "saving $x                                                               \r"
	done
	echo "finished writing to $json_cache_file"
else
	echo "$json_cache_file already present"
fi
