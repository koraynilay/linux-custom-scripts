#!/bin/sh
source $HOME/.config/listenbrainz-mpd-from-logrc

url="https://api.listenbrainz.org/1/submit-listens"
# read from ~/.mpd/log from a certain time to another (quicker but less clean: use line numbers)
json="
{
  \"inserted_at\": $now,
  \"listened_at\": $listen_time,
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

exit 1
curl -X POST $url -H "Authorization: token $(<$TOKEN_FILE)" -d "$json"

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
