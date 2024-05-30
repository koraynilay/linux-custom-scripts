#!/bin/bash
#OFS=$IFS 
#IFS=$'\n' 
mpdfile=$HOME/mpd_log_for_listenbrainz-v2-epoch
while read -r cf1 <&3 && read -r cf2 <&4; do
	echo perl -pi -e "s{\Q\"$cf1\"}{\"$cf2\"}g" $mpdfile
	perl -pi -e "s{\Q\"$cf1\"}{\"$cf2\"}g" $mpdfile
done 3<nntt6 4<nntt62
