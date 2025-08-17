#!/bin/bash
folder="$(<~/.config/instaloader-config)"
cd "$folder"
n=4
profiles=(*)
num_profiles=${#profiles[@]}
single_num=$((num_profiles/n))

set -x
a=${profiles[@]:0:$single_num}
b=${profiles[@]:$single_num:$single_num}
c=${profiles[@]:$single_num*2:$single_num}
d=${profiles[@]:$single_num*3:$num_profiles-$single_num*3}

tmux new-session -s instaloader -c "$folder" \; \
	send-keys -t instaloader "instaloader -b firefox --reels --highlights --stories -F $a" C-m \; \
	split-window -v -t instaloader \; \
	send-keys -t instaloader "instaloader -b firefox --reels --highlights --stories -F $b" C-m \; \
	split-window -v -t instaloader \; \
	send-keys -t instaloader "instaloader -b firefox --reels --highlights --stories -F $c" C-m \; \
	split-window -v -t instaloader \; \
	send-keys -t instaloader "instaloader -b firefox --reels --highlights --stories -F $d" C-m \;
