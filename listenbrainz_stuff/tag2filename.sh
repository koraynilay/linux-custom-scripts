#!/bin/bash
info_func() {
	ret=$(ffprobe -v quiet -show_format -of json "$1" | jq -r "$2 // empty")
	printf '%s' "$ret"
}
recmbid_func() {
	ret=$(mid3v2 -l "$1" | jc --ini --pretty | jq -r "$2 // empty")
	ret=$(grep -Po '[a-z0-9-]{36}' <<< "$ret")
	printf '%s' "$ret"
}
fd_func() {
	printf '%s' "$(fd -g "$2" "$1")"
}

check_if_correct() {
	music_dir="$1"
	tochk_artist="$2"
	tochk_title="$3"
	tochk_album="$4"
	tochk_tracknumber="$5"
	tochk_recording_mbid="$6"

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

	json_cur=$(info_func "$filepath" ".format") # get metadata json
	#printf '%s' "$json_cur"

	duration="$(jq -r '.duration // empty' <<< "$json_cur")" # duration in seconds
	duration=$(calc -p "round($duration * 1000)") # duration is ms (as int)
	if [ "$use_year" -eq 1 ];then
		listened_at=$(date -d "$month $day $year $time" +%s) # get the timestamp for when the listen finished
	else
		listened_at=$(date -d "$month $day $time" +%s) # get the timestamp for when the listen finished
	fi
	date -d @$listened_at
	listened_at=$((listened_at-(duration/1000))) # get the timestamp for when the listen started
	date -d @$listened_at
	track_number=$(jq -r '.tags.track // empty' <<< "$json_cur")

	format=$(jq -r '.format_name' <<< "$json_cur" | tr -d '"') # mp3, flag, whatever

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

get_filename_from_tags_mpd() {
	tochk_artist=""
	tochk_title=""
	tochk_album=""
	tochk_tracknumber=""
	tochk_recording_mbid=""
	artist_query=()
	title_query=()
	album_query=()
	track_query=()

	tochk_artist="$1"
	tochk_title="$2"
	tochk_album="$3"
	tochk_tracknumber="$4"
	tochk_recording_mbid="$5"

	#echo $tochk_artist $tochk_title $tochk_album $tochk_tracknumber $tochk_recording_mbid

	IFS=''
	if [ -n "$tochk_artist" ];then
		artist_query=("artist" "$tochk_artist")
	fi
	if [ -n "$tochk_title" ];then
		title_query=("title" "$tochk_title")
	else
		exit 1
	fi
	if [ -n "$tochk_album" ];then
		album_query=("album" "$tochk_album")
	fi
	if [ -n "$tochk_tracknumber" ];then
		track_query=("track" "$tochk_tracknumber")
	fi

	#echo mpc find ${artist_query[@]} ${title_query[@]} ${album_query[@]} ${track_query[@]}
	#mpc find ${artist_query[@]} ${title_query[@]} ${album_query[@]} ${track_query[@]}

	if [ -z "$tochk_recording_mbid" ];then
		filename=$(mpc find ${artist_query[@]} ${title_query[@]} ${album_query[@]} ${track_query[@]})
	else
		filename=$(mpc find 'MUSICBRAINZ_TRACKID' "$tochk_recording_mbid")
	fi
	printf '%s' "$filename"
}
