#!/bin/sh
backspace_code=22
alt_L_code=64
backspace=$(xmodmap -pke | /bin/grep -P "[^0-9]$backspace_code[^0-9]" | cut -f2 -d'=')
alt=$(xmodmap -pke | /bin/grep -P "[^0-9]$alt_L_code[^0-9]" | cut -f2 -d'=')

if [ "$1" == "on" ];then
	xmodmap -e "keycode $backspace_code = $alt_L_code"
	xmodmap -e "keycode $alt_L_code = $backspace"
else
	xmodmap ~/.Xmodmap
fi
