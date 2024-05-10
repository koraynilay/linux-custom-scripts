#!/bin/bash
. "$HOME/.config/listenbrainz-mpd-from-logrc"

shopt -s expand_aliases
alias jq='jq -r' # needed to remove quotes from json
alias json_metadata_cmd='ffprobe -v quiet -show_format -of json'

music_dir="$MPD_MUSIC_DIR" # taken from the rc at the start, like LISTENBRAINZ_TOKEN_FILE
info_func() {
	ret=$(json_metadata_cmd "$1" | jq "$2 // empty")
	printf '%s' "$ret"
}
recmbid_func() {
	ret=$(mid3v2 -l "$1" | jc --ini --pretty | jq "$2 // empty")
	ret=$(grep -Po '[a-z0-9-]{36}' <<< "$ret")
	printf '%s' "$ret"
}
print_help() {
	echo -ne "Usage: $0 [start line] [end line] [option(s)]\n";
	echo -ne "\nOptions:\n";
	echo -ne "  -n\tdry run, don't send anything to listenbrainz\n";
	echo -ne "  -y\tuse year (need to be manually added it after the date (eg. 'May 05' -> 'May 05 2024')\n";
	echo -ne "  -u\tset api domain (default: $api_domain\n";
	exit 1;
}


# TODO: add --debug|-d and --dry-run|-n and maybe also flags for the token file and music dir

# read from ~/.mpd/log from a certain time to another (quicker but less clean: use line numbers)
sl=${@: -2:1} # start line number
el=${@: -1:1} # end line number # +1 since $2 is the last line to be parsed, but $el is the last line + 1
if [ -z $sl ] || [ -z $el ];then
	print_help
fi
echo $sl $el
el=$((el+1)) # end line number # +1 since $2 is the last line to be parsed, but $el is the last line + 1

dry=0
use_year=0
api_domain='api.listenbrainz.org'
while getopts nyhu opt;do
	case $opt in
		n)dry=1;;
		y)use_year=1;;
		u)api_domain="$OPTARG";;
		h)print_help;;
		?)exit 2;;
	esac
done

url="https://$api_domain/1/submit-listens"

mpd_log_file="$HOME/mpd_log_for_listenbrainz"
echo $el $sl $((el-sl))
to_add="$(tail -n +"$sl" "$mpd_log_file" | head -n $((el-sl)))" # list of lines to parse
jsons=() # array of json of songs to be sent as import
skipped=() # skipped files
IFS=$'\n'

# from https://stackoverflow.com/a/20983251/12206923
# Num  Colour    #define         R G B
# 
# 0    black     COLOR_BLACK     0,0,0
# 1    red       COLOR_RED       1,0,0
# 2    green     COLOR_GREEN     0,1,0
# 3    yellow    COLOR_YELLOW    1,1,0
# 4    blue      COLOR_BLUE      0,0,1
# 5    magenta   COLOR_MAGENTA   1,0,1
# 6    cyan      COLOR_CYAN      0,1,1
# 7    white     COLOR_WHITE     1,1,1
# 
# tput setab [1-7] # Set the background colour using ANSI escape
# tput setaf [1-7] # Set the foreground colour using ANSI escape

err=$(tput setaf 1) # red
warn=$(tput setaf 3) # yellow
reset=$(tput sgr0)

for song in $to_add;do
	#echo -n "$song"
	if [ "$use_year" -eq 1 ];then
		IFS=' ' read month day year time colon logger action filename <<< $song
	else
		IFS=' ' read month day time colon logger action filename <<< $song
	fi
	#echo $logger
	#echo $action

	# skip if not a played action
	# (unfortunately "player: played" is also used when restarting mpd)
	if [ "$logger" != "player:" ] && [ "$action" != "played" ];then
		echo -e "skipping: $song\r"
		continue
	fi
	#echo
	filename=${filename#\"} # remove double quotes (") from around the filename
	filename=${filename%\"} # remove double quotes (") from around the filename
	json_cur=$(info_func "$music_dir/$filename" ".format") # get metadata json
	#printf '%s' "$json_cur"

	duration="$(jq '.duration // empty' <<< "$json_cur")" # duration in seconds
	duration=$(calc -p "round($duration * 1000)") # duration is ms (as int)
	if [ "$use_year" -eq 1 ];then
		listened_at=$(date -d "$month $day $year $time" +%s) # get the timestamp for when the listen finished
	else
		listened_at=$(date -d "$month $day $time" +%s) # get the timestamp for when the listen finished
	fi
	date -d @$listened_at
	listened_at=$((listened_at-(duration/1000))) # get the timestamp for when the listen started
	date -d @$listened_at
	track_number=$(jq '.tags.track // empty' <<< "$json_cur")

	format=$(jq '.format_name' <<< "$json_cur" | tr -d '"') # mp3, flag, whatever

	# check if the files has MusicBrainz tags
	if [ "$format" = "mp3" ];then
		recording_mbid=$(recmbid_func "$music_dir/$filename" ".UFID")
		use_mb=$(grep -cP '[a-z0-9-]{36}' <<< "$recording_mbid")
		#echo "mp3 $use_mb:$recording_mbid"
	elif [ "$format" = "flac" ];then
		recording_mbid="$(jq '.tags."MUSICBRAINZ_TRACKID" // empty' <<< "$json_cur")"
		use_mb=$(grep -cP '[a-z0-9-]{36}' <<< "$recording_mbid")
		#echo "flac $use_mb:$recording_mbid"
	else
		echo "${warn}WARNING: unsupported format, this listen won't be sent to listenbrainz${reset}"
		skipped+=("$filename")
		continue
	fi

	# get tags
	if [ "$format" = "mp3" ];then
		title=$(jq '.tags.title // empty' <<< "$json_cur")
		artist=$(jq '.tags.artist // empty' <<< "$json_cur")
		album=$(jq '.tags.album // empty' <<< "$json_cur")

		if [ "$use_mb" -ge 1 ];then
			track_mbid="$(jq '.tags."MusicBrainz Release Track Id" // empty' <<< "$json_cur")"
			#recording_mbid="$(jq '.tags."" // empty' <<< "$json_cur")" #can't because not stored like the other data
			release_mbid="$(jq '.tags."MusicBrainz Album Id" // empty' <<< "$json_cur")"
			artist_mbid="$(jq '.tags."MusicBrainz Artist Id" // empty' <<< "$json_cur")"
		fi
	elif [ "$format" = "flac" ];then
		title=$(jq '.tags.TITLE // empty' <<< "$json_cur")
		artist=$(jq '.tags.ARTIST // empty' <<< "$json_cur")
		album=$(jq '.tags.ALBUM // empty' <<< "$json_cur")

		if [ "$use_mb" -ge 1 ];then
			track_mbid="$(jq '.tags."MUSICBRAINZ_RELEASETRACKID" // empty' <<< "$json_cur")"
			release_mbid="$(jq '.tags."MUSICBRAINZ_ALBUMID" // empty' <<< "$json_cur")"
			artist_mbid="$(jq '.tags."MUSICBRAINZ_ARTISTID" // empty' <<< "$json_cur")"
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
	#printf '%s\n' "$json"
	json=$(jq -c <<< $json)
	IFS=' ' jsons+=("$json")
done
#for s in "${jsons[@]}" ; do echo "---" $s ; done
#echo jsons:$(IFS=,;echo "${jsons[*]}")

#exit 69
if [ "$dry" -ne 1 ];then
	echo curl $url -X POST \
		-H "Authorization: token $(<$LISTENBRAINZ_TOKEN_FILE)" \
		-H "Content-Type: application/json" \
		-d "{
			\"listen_type\": \"import\",
			\"payload\": [
				$(IFS=, ; echo "${jsons[*]}")
			]
		}"
else
	echo "Dry run, not running curl"
fi
#echo [$(IFS=, ; echo "${jsons[*]}")] | jq
echo "found and sent ${#jsons[@]} listens (check curl output)"
echo "skipped ${#skipped[@]} unsupported files:"
for s in "${skipped[@]}";do
	echo "- $s"
done
