#!/bin/bash
#MYHOST='127.0.0.1' # or your MPD host

mpduri="$(youtube-dl -f best -g $1)#"
TAG=$(echo -n $(youtube-dl -i --get-filename $1) | sed 's/-.\{11\}\..*//g')
#cadena="{\"title\":\"$TAG\"}"
#echo "cadena:$cadena"
mpduri="$mpduri/$TAG"
echo "uri:$mpduri"
mpc insert "$mpduri"
mpc next
mpc play

