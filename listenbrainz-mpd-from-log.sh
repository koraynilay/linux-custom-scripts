#!/bin/sh
. "$HOME/.config/listenbrainz-mpd-from-logrc"

alias jq='jq -r' # needed to remove quotes from json
alias json_metada_cmd='ffprobe -v quiet -show_format -of json'

url="https://api.listenbrainz.org/1/submit-listens"
music_dir="/I/Raccolte/Musica"
info_func() {
	ret=$(json_metada_cmd $1 | jq $2)
	printf '%s' "$ret"
}
recmbid_func() {
	ret=$(mid3v2 -l $1 | jc --ini --pretty | jq $2)
	ret=$(grep -Po '[a-z0-9-]{36}' <<< $ret)
	printf '%s' "$ret"
}

# read from ~/.mpd/log from a certain time to another (quicker but less clean: use line numbers)
sl=$1 # start line number
el=$2 # end line number
mpd_log_file="$HOME/.mpd/log"
to_add="$(tail -n +$sl $mpd_log_file | head -n $(($el-$sl)))"
IFS=$'\n'
recording_mbid="none"
for song in $to_add;do
	echo "csong:$song"
	IFS=' ' read month day time colon logger action filename <<< $song
	if ! [ "$logger" = "player:" ] && [ "$action" = "played" ];then
		continue
	fi
	filename=${filename//\"/}
	json_cur=$(info_func "$music_dir/$filename" ".format")
	recording_mbid=$(recmbid_func "$music_dir/$filename" ".UFID")

	now=$(date +%s)
	listened_at=$(date -d "$month $day $time" +%s)
	printf '%s' "$json_cur"
	printf '\n%s\n' "$recording_mbid"
	format=$(jq '.format_name' <<< $json_cur | tr -d '"')
	if [ "$format" = "mp3" ];then
		title=$(jq '.tags.title' <<< $json_cur)
		artist=$(jq '.tags.artist' <<< $json_cur)
		album=$(jq '.tags.album' <<< $json_cur)

		if [[ "$recording_mbid" =~ [a-z0-9-]{36} ]];then
			track_mbid="$(jq '.tags."MusicBrainz Release Track Id"' <<< $json_cur)"
			#recording_mbid="$(jq '.tags.""' <<< $json_cur)"
			release_mbid="$(jq '.tags."MusicBrainz Album Id"' <<< $json_cur)"
			artist_mbid="$(jq '.tags."MusicBrainz Artist Id"' <<< $json_cur)"
		fi
	elif [ "$format" = "flac" ];then
		title=$(jq '.tags.TITLE' <<< $json_cur)
		artist=$(jq '.tags.ARTIST' <<< $json_cur)
		album=$(jq '.tags.ALBUM' <<< $json_cur)

		if [[ "$recording_mbid" =~ [a-z0-9-]{36} ]];then
			track_mbid="$(jq '.tags."MUSICBRAINZ_RELEASETRACKID"' <<< $json_cur)"
			recording_mbid="$(jq '.tags."MUSICBRAINZ_TRACKID"' <<< $json_cur)"
			release_mbid="$(jq '.tags."MUSICBRAINZ_ALBUMID"' <<< $json_cur)"
			artist_mbid="$(jq '.tags."MUSICBRAINZ_ARTISTID"' <<< $json_cur)"
		fi
	fi
	track_number=$(jq '.tags.track' <<< $json_cur)
	duration="$(jq '.duration' <<< $json_cur)"
	duration=$(calc -p "$duration * 1000")

	if ! [[ "$recording_mbid" =~ [a-z0-9-]{36} ]];then
		json="
		{
		  \"inserted_at\": $now,
		  \"listened_at\": $listened_at,
		  \"track_metadata\": {
		    \"additional_info\": {
		      \"duration_ms\": $duration,
		      \"media_player\": \"MPD\",
		      \"submission_client\": \"listenbrainz-mpd-from-log.sh\",
		    },
		    \"artist_name\": \"$artist\",
		    \"track_name\": \"$title\"
		    \"release_name\": \"$album\",
		  },
		  \"user_name\": \"$USER\"
		}
		"
		printf '%s\n' "$json"
	else
		json="
		{
		  \"inserted_at\": $now,
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
		    \"release_name\": \"$album\",
		  },
		  \"user_name\": \"koraynilay\"
		}
		"
		printf '%s\n' "$json"
	fi
done


exit 1
curl -X POST $url -H "Authorization: token $(<$TOKEN_FILE)" -d "$json"

#{
#  "inserted_at": 1714236481,
#  "listened_at": 1714236392,
#  "recording_msid": "3f65f2e5-8f3a-4467-9ac2-6a52e9052b4e",
#  "track_metadata": {
#    "additional_info": {
#      "artist_mbids": [
#        "a9d3a905-9a5b-4c84-829a-2f8fedf3e513"
#      ],
#      "duration_ms": 176440,
#      "media_player": "MPD",
#      "recording_mbid": "8ed6cb7e-8f37-43da-8f05-0817e477be94",
#      "recording_msid": "3f65f2e5-8f3a-4467-9ac2-6a52e9052b4e",
#      "release_mbid": "21a925c9-1fc1-45e7-a4c0-9424242e8282",
#      "submission_client": "listenbrainz-mpd",
#      "submission_client_version": "2.3.4",
#      "track_mbid": "442995ef-c57f-34fe-a06c-c98d03d5535d",
#      "tracknumber": "10"
#    },
#    "artist_name": "Shintaro Jinbo",
#    "mbid_mapping": {
#      "artist_mbids": [
#        "a9d3a905-9a5b-4c84-829a-2f8fedf3e513"
#      ],
#      "artists": [
#        {
#          "artist_credit_name": "神保伸太郎",
#          "artist_mbid": "a9d3a905-9a5b-4c84-829a-2f8fedf3e513",
#          "join_phrase": ""
#        }
#      ],
#      "caa_id": 6079247992,
#      "caa_release_mbid": "21a925c9-1fc1-45e7-a4c0-9424242e8282",
#      "recording_mbid": "8ed6cb7e-8f37-43da-8f05-0817e477be94",
#      "recording_name": "SCARE SHADOW",
#      "release_mbid": "21a925c9-1fc1-45e7-a4c0-9424242e8282"
#    },
#    "release_name": "Saya no Uta Original Soundtrack",
#    "track_name": "SCARE SHADOW"
#  },
#  "user_name": "koraynilay"
#}

#{
#  "inserted_at": 1714186556,
#  "listened_at": 1714186430,
#  "recording_msid": "4590f2a4-beee-4fd7-91f2-05a02fca718c",
#  "track_metadata": {
#    "additional_info": {
#      "duration_ms": 250128,
#      "media_player": "MPD",
#      "recording_msid": "4590f2a4-beee-4fd7-91f2-05a02fca718c",
#      "submission_client": "listenbrainz-mpd",
#      "submission_client_version": "2.3.4",
#      "tracknumber": "8"
#    },
#    "artist_name": "KEMU VOXX",
#    "track_name": "Life-Cheating Game「イカサマライフゲイム」"
#  },
#  "user_name": "koraynilay"
#}

#{
#  "inserted_at": 1714149285,
#  "listened_at": 1714149194,
#  "recording_msid": "80e1c29c-db5b-4b50-8a83-8cae2c008a90",
#  "track_metadata": {
#    "additional_info": {
#      "duration_ms": 182773,
#      "media_player": "MPD",
#      "recording_msid": "80e1c29c-db5b-4b50-8a83-8cae2c008a90",
#      "submission_client": "listenbrainz-mpd",
#      "submission_client_version": "2.3.4",
#      "tags": [
#        "OST"
#      ],
#      "tracknumber": "10"
#    },
#    "artist_name": "szak, ryo, H.B STUDIO",
#    "release_name": "Wonderful Everyday (Subarashiki Hibi) OST 1",
#    "track_name": "Winner of the Denpa Relay「電波リレーの勝者」"
#  },
#  "user_name": "koraynilay"
#}

#{
#  "listened_at": 1443521965,
#  "track_metadata": {
#    "additional_info": {
#      "release_mbid": "bf9e91ea-8029-4a04-a26a-224e00a83266",
#      "artist_mbids": [
#        "db92a151-1ac2-438b-bc43-b82e149ddd50"
#      ],
#      "recording_mbid": "98255a8c-017a-4bc7-8dd6-1fa36124572b",
#      "tags": [ "you", "just", "got", "rick rolled!"]
#    },
#    "artist_name": "Rick Astley",
#    "track_name": "Never Gonna Give You Up",
#    "release_name": "Whenever you need somebody"
#  }
#}
