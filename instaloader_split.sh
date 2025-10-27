#!/bin/bash
folder="$(<~/.config/instaloader-config)"
cd "$folder"
n=4
profiles=(*)
num_profiles=${#profiles[@]}
single_num=$((num_profiles/n))

a=${profiles[@]:0:$single_num}
b=${profiles[@]:$single_num:$single_num}
c=${profiles[@]:$single_num*2:$single_num}
d=${profiles[@]:$single_num*3:$num_profiles-$single_num*3}

set -x

session_name="instaloader"
options="--user-agent 'Mozilla/5.0 (X11; Linux x86_64; rv:143.0) Gecko/20100101 Firefox/143.0' --reels --highlights --stories -F"
tmux kill-session -t "$session_name"
systemd-run --scope --user tmux new-session -d -s "$session_name" -c "$folder" \; \
	send-keys -t instaloader "for p in $a; do instaloader -b firefox $options \$p; sleep 5; done" C-m \; \
	split-window -v -t instaloader \; \
	send-keys -t instaloader "for p in $b; do instaloader -b firefox $options \$p; sleep 5; done" C-m \; \
	split-window -v -t instaloader \; \
	send-keys -t instaloader "for p in $c; do instaloader -b firefox $options \$p; sleep 5; done" C-m \; \
	split-window -v -t instaloader \; \
	send-keys -t instaloader "for p in $d; do instaloader -b firefox $options \$p; sleep 5; done" C-m \;
