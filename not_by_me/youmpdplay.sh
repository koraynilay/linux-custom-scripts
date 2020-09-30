#!/bin/bash
#
MYHOST='192.168.1.128' # or your MPD host

mpduri="$(youtube-dl -f best -g $1)#"
TAG=$(youtube-dl -i --get-filename $1)
cadena="{\"title\":\"$TAG\"}"
echo "$cadena"
mpduri="$mpduri$cadena"
echo "$mpduri"
mpc insert "$mpduri"
mpc next
mpc play
