#!/bin/sh
backspace=$(xmodmap -pke | /bin/grep -F 'BackSpace')
backspace_string=$(echo $backspace | cut -f2 -d'=')
backspace_code=$(echo $backspace | cut -f1 -d'=')
alt=$(xmodmap -pke | /bin/grep -F 'BackSpace')
