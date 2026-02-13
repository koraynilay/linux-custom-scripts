#!/bin/bash
source $PLAYERS_FILE

if [ -z "$PLAYERS_FILE" ] || [ -z "$CTFD_IP" ] || [ -z "$CTFD_PORT" ] || [ -z "$CTFD_TOKEN" ]; then
	echo "CTFD_IP, CTFD_PORT, and CTFD_TOKEN environment variables must be set."
	exit 1
fi

ip=$CTFD_IP
port=$CTFD_PORT
token=$CTFD_TOKEN

for mail in "${!players[@]}"; do
	curl -X POST "$ip:$port/api/v1/users?notify=true" -H "content-type: application/json" -H "Authorization: Token $token" \
		-d '{
			"name":"'"${players[$mail]}"'",
			"email":"'"$mail"'",
			"password":"'"$(cat /dev/random | tr -dc 'a-zA-Z0-9' | fold -w 25 | head -n 1 | tr -d '\n')"'",
			"type":"user",
			"verified":false,
			"hidden":false,
			"banned":false,
			"affiliation":"'"${playerconfs[$mail]}"'",
			"fields":[]
		}'
done
