#!/bin/sh
xmodmap_file="$HOME/.Xmodmap"
switch_key() {
	code1=$1
	code2=$2
	string1=$(xmodmap -pke | /bin/grep -P "[^0-9]$code1[^0-9]" | cut -f2 -d'=')
	string2=$(xmodmap -pke | /bin/grep -P "[^0-9]$code2[^0-9]" | cut -f2 -d'=')

	xmodmap -e "keycode $code1 = $string2"
	xmodmap -e "keycode $code2 = $string1"
}

if [ "$1" == "on" ];then
	#22 = BackSpace, 134 = Super_R, 64 = Alt_L, 36 = Return
	switch_key 22 64
	switch_key 134 36
else
	xmodmap $xmodmap_file
fi
