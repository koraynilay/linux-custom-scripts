#!/bin/sh
uplay_folder="$HOME/Games/uplay"
bck_folder="$HOME/bck_savegames/uplay"
cd "$uplay_folder"
cp -vir 'drive_c/users/koraynilay/Local Settings/Application Data/Ubisoft Game Launcher/spool' "$bck_folder"
cp -vir 'drive_c/Program Files (x86)/Ubisoft/Ubisoft Game Launcher/savegames' "$bck_folder"
cd "$bck_folder"
echo -e "./push.sh [y/n]?:"
read aann
if [ "$aann" = "y" ];then
	./push.sh
fi
