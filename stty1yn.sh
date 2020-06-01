#!/bin/sh
h=$HOME #zprofile location
sscrpt='starti3' #scprit/command to substitute (don't use "/")
case $1 in
	y|yes|on|true)sed -i "s/echo no start \#$sscrpt/$sscrpt/" "$h/.zprofile";;
	n|no|off|false)sed -i "s/$sscrpt/echo no start \#$sscrpt/" "$h/.zprofile";;
	*)printf "Usage:\n$0 [y|yes|on|true]\tto enable autostart de/wm\n$0 [n|no|off|false]\tto disable autostart de/wm\n"
esac
