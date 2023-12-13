#!/bin/sh
delis() {
	curl https://api.listenbrainz.org/1/delete-listen \
			-H "Authorization: Token $(tr -d '\n' < .env)" \
			-H "Content-Type: application/json" \
			-X POST \
			-d "{
				\"listened_at\": $1,
				\"recording_msid\":\"$2\"
			}" --write-out "%{http_code}" --silent --output /dev/null
}

while read a; do 
	la="$(echo $a | cut -f2 -d' ')"
	msid="$(echo $a | cut -f1 -d' ')"
	echo $la $msid
	ret="$(delis $la $msid)";
	echo $ret
	while [ $ret == "429" ];do
		sleep 5;
		ret="$(delis $la $msid)";
		echo while: $ret
	done
	sleep 0.2;
done < abcd_la


# jq '.[] | select(.track_metadata.additional_info.media_player == "org.kde.kdeconnect_tp") | "\(.recording_msid) \(.listened_at)"' listens.json | tr -d '"' >> abcd_la
# listens.json is the downloaded json from listenbrainz
# https://zerokspot.com/weblog/2013/07/18/processing-json-with-jq/
# https://stackoverflow.com/a/18608100
