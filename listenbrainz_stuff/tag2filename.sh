#!/bin/bash
# $1: filename, $2: json key to get (optional)
info_func() {
	local ret=$(ffprobe -v quiet -show_format -of json "$1" | jq -r "${2:='.'} // empty")
	printf '%s' "$ret"
}

# $1: filename, $2: recording_mbid key (e.g. ".UFID" for mp3)
recmbid_func() {
	local ret=$(mid3v2 -l "$1" | jc --ini --pretty | jq -r "$2 // empty")
	ret=$(grep -Po '[a-z0-9-]{36}' <<< "$ret")
	printf '%s' "$ret"
}

# $1: filename to find, $2: dir to find $1 in
fd_func() {
	printf '%s' "$(fd -g "$2" "$1")"
}

# $1: key, $2: json object
get_json_value() {
	local ret="$(jq -r ".\"$1\" // empty" <<< "$2")"
	printf '%s' "$ret"
}

get_filename_from_tags_mpd() {
	local tochk_artist="$1"
	local tochk_title="$2"
	local tochk_album="$3"
	local tochk_tracknumber="$4"
	local tochk_recording_mbid="$5"

	#echo $tochk_artist $tochk_title $tochk_album $tochk_tracknumber $tochk_recording_mbid

	local IFS=''
	if [ -n "$tochk_artist" ];then
		local artist_query=("artist" "$tochk_artist")
	fi
	if [ -n "$tochk_title" ];then
		local title_query=("title" "$tochk_title")
	else
		exit 1
	fi
	if [ -n "$tochk_album" ];then
		local album_query=("album" "$tochk_album")
	fi
	if [ -n "$tochk_tracknumber" ];then
		local track_query=("track" "$tochk_tracknumber")
	fi

	#echo mpc find ${artist_query[@]} ${title_query[@]} ${album_query[@]} ${track_query[@]}
	#mpc find ${artist_query[@]} ${title_query[@]} ${album_query[@]} ${track_query[@]}

	if [ -z "$tochk_recording_mbid" ];then
		local filename=$(mpc find ${artist_query[@]} ${title_query[@]} ${album_query[@]} ${track_query[@]})
	else
		local filename=$(mpc find 'MUSICBRAINZ_TRACKID' "$tochk_recording_mbid")
	fi
	printf '%s' "$filename"
}

# array of JSONs passed as argument
# need $LISTENBRAINZ_TOKEN_FILE and $LISTEBRAINZ_API_URL to be set in the caller
listenbrainz_submit_import() {
	local func_name="listenbrainz_submit_import"
	local log_start="$func_name(): "

	local token=""
	if [ -n "$LISTENBRAINZ_TOKEN" ];then
		token="$LISTENBRAINZ_TOKEN"
	elif [ -n "$LISTENBRAINZ_TOKEN_FILE" ];then
		token="$(<$LISTENBRAINZ_TOKEN_FILE)"
	else
		token="no token provided"
		echo $log_start'Missing ListenBrainz token, use either $LISTENBRAINZ_TOKEN_FILE or $LISTENBRAINZ_TOKEN'
		exit 5
	fi

	local api_domain="api.listenbrainz.org"
	local url="https://$api_domain/1/submit-listens"
	if [ -n "$LISTEBRAINZ_API_DOMAIN" ];then
		url="$LISTEBRAINZ_API_DOMAIN"
	fi
	if [ "$LISTENBRAINZ_IMPORT_DEBUG" -eq 1 ];then
		echo $log_start"Using '$api_domain' as domain for the listenbrainz api; complete url is: $url"
	fi

	local echo=""
	if [ "$LISTENBRAINZ_IMPORT_DRY" -eq 1 ];then
		echo="echo"
	fi


	local jsons=("$@")
	#echo ${jsons[0]}
	#echo ${jsons[1]}

	local payload="$(local IFS=, ; echo "${jsons[*]}")"

	$echo curl "$url" -X POST \
		-H "Authorization: token $token" \
		-H "Content-Type: application/json" \
		-d "{
			\"listen_type\": \"import\",
			\"payload\": [
				$payload
			]
		}"
}

check_if_correct() {
	local music_dir="$1"
	local tochk_artist="$2"
	local tochk_title="$3"
	local tochk_album="$4"
	local tochk_tracknumber="$5"
	local tochk_recording_mbid="$6"
	local filename=""
	local filepath=""

	echo md:$music_dir at:$tochk_artist tt:$tochk_title ab:$tochk_album tn:$tochk_tracknumber rmbid:$tochk_recording_mbid

	# try full (mp3, flac)
		filename="$tochk_tracknumber - $tochk_artist - $tochk_title - $tochk_album.mp3"
	filepath=$(fd_func "$music_dir" "$filename")
	if [ -z "$filepath" ];then
		filename="$tochk_tracknumber - $tochk_artist - $tochk_title - $tochk_album.flac"
	fi
	filepath=$(fd_func "$music_dir" "$filename")


	# try without track number (mp3, flac)
	if [ -z "$filepath" ];then
		filename="$tochk_artist - $tochk_title - $tochk_album.mp3"
	fi
	filepath=$(fd_func "$music_dir" "$filename")
	if [ -z "$filepath" ];then
		filename="$tochk_artist - $tochk_title - $tochk_album.flac"
	fi
	filepath=$(fd_func "$music_dir" "$filename")


	# try with blank album field (mp3, flac)
	if [ -z "$filepath" ];then
		filename="$tochk_artist - $tochk_title -.mp3"
	fi
	filepath=$(fd_func "$music_dir" "$filename")
	if [ -z "$filepath" ];then
		filename="$tochk_artist - $tochk_title -.flac"
	fi
	filepath=$(fd_func "$music_dir" "$filename")


	# try without album field (mp3, flac)
	if [ -z "$filepath" ];then
		filename="$tochk_artist - $tochk_title.mp3"
	fi
	filepath=$(fd_func "$music_dir" "$filename")
	if [ -z "$filepath" ];then
		filename="$tochk_artist - $tochk_title.flac"
	fi
	filepath=$(fd_func "$music_dir" "$filename")


	# try without artist with "-" delim (mp3, flac)
	if [ -z "$filepath" ];then
		filename="$tochk_tracknumber - $tochk_title.mp3"
	fi
	filepath=$(fd_func "$music_dir" "$filename")
	if [ -z "$filepath" ];then
		filename="$tochk_tracknumber - $tochk_title.flac"
	fi
	filepath=$(fd_func "$music_dir" "$filename")


	# try without artist with "." delim (mp3, flac)
	if [ -z "$filepath" ];then
		filename="$tochk_tracknumber. $tochk_title.mp3"
	fi
	filepath=$(fd_func "$music_dir" "$filename")
	if [ -z "$filepath" ];then
		filename="$tochk_tracknumber. $tochk_title.flac"
	fi
	filepath=$(fd_func "$music_dir" "$filename")


	# try with just title (mp3, flac)
	if [ -z "$filepath" ];then
		filename="$tochk_title.mp3"
	fi
	filepath=$(fd_func "$music_dir" "$filename")
	if [ -z "$filepath" ];then
		filename="$tochk_title.flac"
	fi
	filepath=$(fd_func "$music_dir" "$filename")


	# can't find it
	if [ -z "$filepath" ];then
		printf 'false'
		exit 1
	fi

	echo found:$filepath
	exit 0

	local json_cur=$(info_func "$filepath" ".format") # get metadata json
	#printf '%s' "$json_cur"

	local duration="$(jq -r '.duration // empty' <<< "$json_cur")" # duration in seconds
	duration=$(calc -p "round($duration * 1000)") # duration is ms (as int)
	local listened_at=""
	if [ "$use_year" -eq 1 ];then
		listened_at=$(date -d "$month $day $year $time" +%s) # get the timestamp for when the listen finished
	else
		listened_at=$(date -d "$month $day $time" +%s) # get the timestamp for when the listen finished
	fi
	date -d @$listened_at
	listened_at=$((listened_at-(duration/1000))) # get the timestamp for when the listen started
	date -d @$listened_at
	local track_number=$(jq -r '.tags.track // empty' <<< "$json_cur")

	local format=$(jq -r '.format_name' <<< "$json_cur" | tr -d '"') # mp3, flag, whatever

	local recording_mbid=""
	local use_mb=""
	# check if the files has MusicBrainz tags
	if [ "$format" = "mp3" ];then
		recording_mbid=$(recmbid_func "$music_dir/$filename" ".UFID")
		use_mb=$(grep -cP '[a-z0-9-]{36}' <<< "$recording_mbid")
		echo "mp3 $use_mb:$recording_mbid"
	elif [ "$format" = "flac" ];then
		recording_mbid="$(jq -r '.tags."MUSICBRAINZ_TRACKID" // empty' <<< "$json_cur")"
		use_mb=$(grep -cP '[a-z0-9-]{36}' <<< "$recording_mbid")
		echo "flac $use_mb:$recording_mbid"
	else
		echo "${warn}WARNING: unsupported format, this listen won't be sent to listenbrainz${reset}"
		skipped+=("$filename")
		continue
	fi

	local title=""
	local artist=""
	local album=""
	local track_mbid=""
	local release_mbid=""
	local artist_mbid=""
	# get tags
	if [ "$format" = "mp3" ];then
		title=$(jq -r '.tags.title // empty' <<< "$json_cur")
		artist=$(jq -r '.tags.artist // empty' <<< "$json_cur")
		album=$(jq -r '.tags.album // empty' <<< "$json_cur")

		if [ "$use_mb" -ge 1 ];then
			track_mbid="$(jq -r '.tags."MusicBrainz Release Track Id" // empty' <<< "$json_cur")"
			#recording_mbid="$(jq -r '.tags."" // empty' <<< "$json_cur")" #can't because not stored like the other data
			release_mbid="$(jq -r '.tags."MusicBrainz Album Id" // empty' <<< "$json_cur")"
			artist_mbid="$(jq -r '.tags."MusicBrainz Artist Id" // empty' <<< "$json_cur")"
		fi
	elif [ "$format" = "flac" ];then
		title=$(jq -r '.tags.TITLE // empty' <<< "$json_cur")
		artist=$(jq -r '.tags.ARTIST // empty' <<< "$json_cur")
		album=$(jq -r '.tags.ALBUM // empty' <<< "$json_cur")

		if [ "$use_mb" -ge 1 ];then
			track_mbid="$(jq -r '.tags."MUSICBRAINZ_RELEASETRACKID" // empty' <<< "$json_cur")"
			release_mbid="$(jq -r '.tags."MUSICBRAINZ_ALBUMID" // empty' <<< "$json_cur")"
			artist_mbid="$(jq -r '.tags."MUSICBRAINZ_ARTISTID" // empty' <<< "$json_cur")"
		fi
	fi

	if [ "$tochk_artist" != "$artist" ];then
		printf 'false'
		exit 1
	fi
	if [ "$tochk_title" != "$title" ];then
		printf 'false'
		exit 1
	fi
	if [ "$tochk_album" != "$album" ];then
		printf 'false'
		exit 1
	fi
	if [ "$tochk_tracknumber" != "$track_number" ];then
		printf 'false'
		exit 1
	fi
	if [ "$use_mb" -ge 1 ];then
		if [ "$tochk_recording_mbid" != "$release_mbid" ];then
			printf 'false'
			exit 1
		fi
	fi

	exit 0
}

get_listenbrainz_json() {
	local func_name="listenbrainz_submit_json"
	local log_start="$func_name(): "
	local filename="$1"
	local timestamp="$2"
	local ts_end="${3:-'false'}"

	local json_cur=$(info_func "$filename" ".format") # get metadata json
	#printf '%s' "$json_cur"

	local duration=""
	duration=$(get_json_value "duration" "$json_cur")
	duration=$(calc -p "round($duration * 1000)") # duration is ms (as int)

	local listened_at=""
	listened_at=$(date -d "$timestamp" +%s) # get the timestamp for when the listen finished
	#date -d @$listened_at
	if [ "$ts_end" -eq "true" ];then
		listened_at=$((listened_at-(duration/1000))) # get the timestamp for when the listen started
		#date -d @$listened_at
	fi

	local track_number=$(get_json_value 'tags.track' "$json_cur")

	local format=$(jq '.format_name' <<< "$json_cur" | tr -d '"') # mp3, flag, whatever

	local recording_mbid=""
	local use_mb=""
	# check if the files has MusicBrainz tags
	if [ "$format" = "mp3" ];then
		recording_mbid=$(recmbid_func "$filename" ".UFID")
		use_mb=$(grep -cP '[a-z0-9-]{36}' <<< "$recording_mbid")
		#echo "mp3 $use_mb:$recording_mbid"
	elif [ "$format" = "flac" ];then
		recording_mbid="$(get_json_value 'tags."MUSICBRAINZ_TRACKID"' "$json_cur")"
		use_mb=$(grep -cP '[a-z0-9-]{36}' <<< "$recording_mbid")
		#echo "flac $use_mb:$recording_mbid"
	else
		#echo "listenbrainz_submit_json(): unsupported format, this listen won't be sent to listenbrainz${reset}"
		printf 'error: unsupported format'
	fi

	local title=""
	local artist=""
	local album=""

	local track_mbid=""
	local release_mbid=""
	local artist_mbid=""

	# get tags
	if [ "$format" = "mp3" ];then
		title=$(get_json_value 'tags.title' "$json_cur")
		artist=$(get_json_value 'tags.artist' "$json_cur")
		album=$(get_json_value 'tags.album' "$json_cur")

		if [ "$use_mb" -ge 1 ];then
			track_mbid="$(get_json_value 'tags."MusicBrainz Release Track Id"' "$json_cur")"
			#recording_mbid="$(get_json_value 'tags.""' "$json_cur")" #can't because not stored like the other data
			release_mbid="$(get_json_value 'tags."MusicBrainz Album Id"' "$json_cur")"
			artist_mbid="$(get_json_value 'tags."MusicBrainz Artist Id"' "$json_cur")"
		fi
	elif [ "$format" = "flac" ];then
		title=$(get_json_value 'tags.TITLE' "$json_cur")
		artist=$(get_json_value 'tags.ARTIST' "$json_cur")
		album=$(get_json_value 'tags.ALBUM' "$json_cur")

		if [ "$use_mb" -ge 1 ];then
			track_mbid="$(get_json_value 'tags."MUSICBRAINZ_RELEASETRACKID"' "$json_cur")"
			release_mbid="$(get_json_value 'tags."MUSICBRAINZ_ALBUMID"' "$json_cur")"
			artist_mbid="$(get_json_value 'tags."MUSICBRAINZ_ARTISTID"' "$json_cur")"
		fi
	fi

	if [ "$use_mb" -ge 1 ];then
		# json with MusicBrainz tags
		json="
		{
		  \"listened_at\": $listened_at,
		  \"track_metadata\": {
		    \"additional_info\": {
		      \"artist_mbids\": [
			\"$artist_mbid\"
		      ],
		      \"duration_ms\": $duration,
		      \"media_player\": \"MPD\",
		      \"recording_mbid\": \"$recording_mbid\",
		      \"release_mbid\": \"$release_mbid\",
		      \"submission_client\": \"listenbrainz-mpd-from-logs.sh\",
		      \"track_mbid\": \"$track_mbid\",
		      \"tracknumber\": \"$track_number\"
		    },
		    \"artist_name\": \"$artist\",
		    \"track_name\": \"$title\"
		    $(if [ -n "$album" ];then echo ,\"release_name\": \"$album\";fi)
		  }
		}
		"
	else
		# json with MusicBrainz tags
		json="
		{
		  \"listened_at\": $listened_at,
		  \"track_metadata\": {
		    \"additional_info\": {
		      \"duration_ms\": $duration,
		      \"media_player\": \"MPD\",
		      \"submission_client\": \"listenbrainz-mpd-from-log.sh\"
		    },
		    \"artist_name\": \"$artist\",
		    \"track_name\": \"$title\"
		    $(if [ -n "$album" ];then echo ,\"release_name\": \"$album\";fi)
		  }
		}
		"
	fi
	printf '%s\n' "$json"
}
