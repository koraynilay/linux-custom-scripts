killall picom
while pgrep -u $UID -x "picom*">/dev/null; do sleep 0.1; done
picom -b --experimental-backends
