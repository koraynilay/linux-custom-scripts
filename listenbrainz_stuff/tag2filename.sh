#!/bin/bash
# $1: filename, $2: json key to get (optional)
info_func() {
	local ret=$(ffprobe -v quiet -show_format -of json "$1" | jq -r "${2:=.} // empty")
	printf '%s' "$ret"
}

info_func_mpd() {
	#declare -x MPC_FORMAT='{
	#	"duration": "%time%",
	#	"musicbrainz_artistid": "%MUSICBRAINZ_ARTISTID%",
	#	"musicbrainz_albumid": "%MUSICBRAINZ_ALBUMID%",
	#	"musicbrainz_albumartistid": "%MUSICBRAINZ_ALBUMARTISTID%",
	#	"musicbrainz_workid": "%MUSICBRAINZ_WORKID%",
	#	"musicbrainz_trackid": "%MUSICBRAINZ_TRACKID%",
	#	"musicbrainz_releasetrackid": "%MUSICBRAINZ_RELEASETRACKID%",
	#	"title": "%title%",
	#	"artist": "%artist%",
	#	"album": "%album%",
	#	"track_number": "%track%"
	#}'
	local MPD_HOST="localhost"
	local MPD_PORT="6600"
	local filename="$1"
	local key="${2:-.}"
	#local ret=$(mpc find filename "$filename" | jq -r "$key // empty")

	#local ret=$(printf '%s\n%s\n' "search filename \"$filename\"" "close" | nc $MPD_HOST $MPD_PORT | \
	#	jc --ini --pretty | jq -r "$key // empty"
	#)

	local ret=$(printf '%s\n%s\n' "find filename \"$filename\"" "close" | nc $MPD_HOST $MPD_PORT | \
		sed -E \
		-e 's/\\/\\\\/g' \
		-e 's/"/\\"/g' \
		-e 's/^OK MPD [0-9]\.[0-9]{2}\.[0-9]$/{"json_start":"",/g' \
		-e 's/([^:]*): (.*)/"\1": "\2",/g' \
		-e 's/^OK$/"json_end":""}/g'
	)
	#if [[ "$ret" =~ '^\{"json_start":"",.*,.*"json_end":""\}' ]];then # works in zsh but not bash
	if [[ "$ret" =~ ^\{\"json_start\":\"\",.*,.*\"json_end\":\"\"\}$ ]];then
		printf '%s' "$ret"
	fi

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
	#local ret="$(jq --arg key "$1" '.[$key] // empty' <<< "$2")"
	#eval "$(jq -r --arg key "$1" ' @sh "local ret="\(.$key)' <<< "$2")"
	local ret="$(jq ".[\"$1\"]  // empty" <<< "$2")"
	ret=${ret#\"}
	ret=${ret%\"}
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
	local func_name="$FUNCNAME"
	local log_start="$func_name(): "
	local from_file="false"
	if [ "$1" = "true" ];then
		from_file="true"
	fi

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
	if [ "${LISTENBRAINZ_IMPORT_DEBUG:=0}" -eq 1 ];then
		echo $log_start"Using '$api_domain' as domain for the listenbrainz api; complete url is: $url"
	fi

	local echo=""
	if [ "${LISTENBRAINZ_IMPORT_DRY:=0}" -eq 1 ];then
		echo="echo"
	fi
	
	IFS=""
	local payload=""
	if [ "$from_file" = "true" ];then
		local datafile=$2
		payload="$(<$datafile)"
	else
		local jsons=("$@")
		#echo ${jsons[0]}
		#echo ${jsons[1]}
		payload="$(local IFS=, ; echo "${jsons[*]}")"

	fi

	local data="{
			\"listen_type\": \"import\",
			\"payload\": [
				$payload
			]
		}"

	if [ "${LISTENBRAINZ_IMPORT_DEBUG}" -eq 1 ];then
		echo $data
	fi

	# no need to compact the json, curl will do it
	$echo curl "$url" -X POST \
		-H "Authorization: token $token" \
		-H "Content-Type: application/json" \
		-d '@-' <<-EOF
				$data
			EOF
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
	local func_name="$FUNCNAME"
	local log_start="$FUNCNAME(): "

	# args
	local filename="$1"
	local timestamp="$2"
	local ts_end="${3:-false}"
	local ts_epoch="${4:-false}"
	local media_player="${5:-unknown}"
	local submission_client="${6:-tag2filename.sh}"

	local json_cur=$(info_func "$filename" ".format") # get metadata json
	if [ -z "$json_cur" ];then
		exit 249
	fi
	#printf '%s' "$json_cur"

	local duration=""
	duration=$(get_json_value "duration" "$json_cur")
	duration=$(calc -p "round($duration * 1000)") # duration is ms (as int)

	local listened_at=""
	if [ "$ts_epoch" != "true" ];then
		listened_at=$(date -d "$timestamp" +%s) # get the timestamp for when the listen finished
		if [ "$ts_end" = "true" ];then
			listened_at=$((listened_at-(duration/1000))) # get the timestamp for when the listen started
		fi
	else
		listened_at="$timestamp"
	fi

	local format=$(get_json_value 'format_name' "$json_cur") # mp3, flag, whatever

	local json_tags="$(get_json_value "tags" "$json_cur")" # get .tags

	local recording_mbid=""
	local use_mb=0
	# check if the files has MusicBrainz tags
	if [ "$format" = "mp3" ];then
		recording_mbid=$(recmbid_func "$filename" ".UFID")
		use_mb=$(grep -cP '[a-z0-9-]{36}' <<< "$recording_mbid")
		#echo "mp3 $use_mb:$recording_mbid"
	elif [ "$format" = "flac" ];then
		recording_mbid="$(get_json_value 'MUSICBRAINZ_TRACKID' "$json_tags")"
		use_mb=$(grep -cP '[a-z0-9-]{36}' <<< "$recording_mbid")
		#echo "flac $use_mb:$recording_mbid"
	else
		#echo "listenbrainz_submit_json(): unsupported format, this listen won't be sent to listenbrainz${reset}"
		printf "error for $filename: unsupported format"
		exit 2
	fi

	local title=""
	local artist=""
	local album=""

	local track_mbid=""
	local release_mbid=""
	local artist_mbid=""

	local track_number=$(get_json_value 'track' "$json_tags")

	# get tags
	if [ "$format" = "mp3" ];then
		title=$(get_json_value 'title' "$json_tags")
		artist=$(get_json_value 'artist' "$json_tags")
		album=$(get_json_value 'album' "$json_tags")

		if [ "$use_mb" -ge 1 ];then
			track_mbid="$(get_json_value 'MusicBrainz Release Track Id' "$json_tags")"
			#recording_mbid="$(get_json_value 'tags.""' "$json_tags")" #can't because not stored like the other data
			release_mbid="$(get_json_value 'MusicBrainz Album Id' "$json_tags")"
			artist_mbid="$(get_json_value 'MusicBrainz Artist Id' "$json_tags")"
		fi
	elif [ "$format" = "flac" ];then
		title=$(get_json_value 'TITLE' "$json_tags")
		artist=$(get_json_value 'ARTIST' "$json_tags")
		album=$(get_json_value 'ALBUM' "$json_tags")

		if [ "$use_mb" -ge 1 ];then
			track_mbid="$(get_json_value 'MUSICBRAINZ_RELEASETRACKID' "$json_tags")"
			release_mbid="$(get_json_value 'MUSICBRAINZ_ALBUMID' "$json_tags")"
			artist_mbid="$(get_json_value 'MUSICBRAINZ_ARTISTID' "$json_tags")"
		fi
	fi

	#artist="${artist//\"/\\\"}"
	#title="${title//\"/\\\"}"
	#album="${album//\"/\\\"}"
	#media_player="${media_player//\"/\\\"}"
	#submission_client="${submission_client//\"/\\\"}"

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
		      \"media_player\": \"$media_player\",
		      \"recording_mbid\": \"$recording_mbid\",
		      \"release_mbid\": \"$release_mbid\",
		      \"submission_client\": \"$submission_client\",
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
		      \"media_player\": \"$media_player\",
		      \"submission_client\": \"$submission_client\"
		    },
		    \"artist_name\": \"$artist\",
		    \"track_name\": \"$title\"
		    $(if [ -n "$album" ];then echo ,\"release_name\": \"$album\";fi)
		  }
		}
		"
	fi

	json=$(jq -c '.' <<< "$json")
	printf '%s\n' "$json"
}

get_listenbrainz_json_mpd() {
	local func_name="$FUNCNAME"
	local log_start="$func_name(): "

	# args
	local filename="$1"
	local timestamp="$2"
	local ts_end="${3:-false}"
	local ts_epoch="${4:-false}"
	local media_player="${5:-unknown}"
	local submission_client="${6:-tag2filename.sh}"

	local json_cur=$(info_func_mpd "$filename") # get metadata json
	if [ -z "$json_cur" ];then
		exit 249
	fi
	#printf '%s' "$json_cur"

	local duration=""
	duration=$(get_json_value "duration" "$json_cur")
	duration=$(calc -p "round($duration * 1000)") # duration is ms (as int)

	local listened_at=""
	if [ "$ts_epoch" != "true" ];then
		listened_at=$(date -d "$timestamp" +%s) # get the timestamp for when the listen finished
		if [ "$ts_end" = "true" ];then
			listened_at=$((listened_at-(duration/1000))) # get the timestamp for when the listen started
		fi
	else
		listened_at="$timestamp"
	fi

	json=$(./tagsjson2listenbrainzjson.pl lbj "$json_cur" "$listened_at" "$duration" "$media_player" "$submission_client")
	printf '%s\n' "$json"
}

get_almost_listenbrainz_json_mpd() {
	local func_name="$FUNCNAME"
	local log_start="$func_name(): "

	# args
	local filename="$1"
	local media_player="${2:-unknown}"
	local submission_client="${3:-tag2filename.sh}"

	local json_cur=$(info_func_mpd "$filename") # get metadata json
	if [ -z "$json_cur" ];then
		exit 249
	fi
	#printf '%s' "$json_cur"

	local duration=""
	duration=$(get_json_value "duration" "$json_cur")
	duration=$(calc -p "round($duration * 1000)") # duration is ms (as int)

	json=$(./tagsjson2listenbrainzjson.pl albj "$json_cur" "$duration" "$media_player" "$submission_client")
	local json_ret="$?"
	printf '%s\n' "$json"
	unset json
	return $json_ret
}

#get_listenbrainz_json_mpd_jq() {
#	local func_name="$FUNCNAME"
#	local log_start="$func_name(): "
#
#	# args
#	local filename="$1"
#	local timestamp="$2"
#	local ts_end="${3:-false}"
#	local ts_epoch="${4:-false}"
#	local media_player="${5:-unknown}"
#	local submission_client="${6:-tag2filename.sh}"
#
#	local json_cur=$(info_func_mpd "$filename") # get metadata json
#	#printf '%s' "$json_cur"
#
#	local duration=""
#	duration=$(get_json_value "duration" "$json_cur")
#	duration=$(calc -p "round($duration * 1000)") # duration is ms (as int)
#
#	local listened_at=""
#	if [ "$ts_epoch" != "true" ];then
#		listened_at=$(date -d "$timestamp" +%s) # get the timestamp for when the listen finished
#		if [ "$ts_end" = "true" ];then
#			listened_at=$((listened_at-(duration/1000))) # get the timestamp for when the listen started
#		fi
#	else
#		listened_at="$timestamp"
#	fi
#
#	if [ "$use_mb" -ge 1 ];then
#		json=$(jq ". | 
#			\"listened_at\" => $listened_at,
#			\"track_metadata\" => {
#				'additional_info' => {
#					'artist_mbids' => [
#						.MUSICBRAINZ_ARTISTID
#					],
#					\"duration_ms\" => $duration,
#					\"media_player\" => $media_player,
#					\"recording_mbid\" => .MUSICBRAINZ_TRACKID,
#					\"release_mbid\" => .MUSICBRAINZ_ALBUMID,
#					\"submission_client\" => $submission_client,
#					\"track_mbid\" => .MUSICBRAINZ_RELEASETRACKID,
#					\"tracknumber\" => .Track
#				},
#				\"artist_name\" => .Artist,
#				\"track_name\" => .Title,
#				\"release_name\" => .Album
#			}
#			"
#		)
#	else
#		json=$(jq ". | 
#			\"listened_at\" => $listened_at,
#			\"track_metadata\" => {
#				'additional_info' => {
#					\"duration_ms\" => $duration,
#					\"media_player\" => $media_player,
#					\"submission_client\" => $submission_client,
#					\"tracknumber\" => .Track
#				},
#				\"artist_name\" => .Artist,
#				\"track_name\" => .Title,
#				\"release_name\" => .Album
#			}
#			"
#		)
#	fi
#	printf '%s\n' "$json"
#}
