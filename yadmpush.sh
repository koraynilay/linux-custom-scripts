yadm status
sleep 3
yadm add -u
yadm commit -m "$(date +'%Y-%m-%d %H:%M:%S')"
yadm push
