#!/bin/sh
uplay_folder="$HOME/Games/uplay"
bck_folder="$HOME/bck_savegames"
uplaybck_folder="${bck_folder}/uplay"
cd "$uplay_folder"
cp -vir 'drive_c/users/koraynilay/Local Settings/Application Data/Ubisoft Game Launcher/spool' "$uplaybck_folder"
cp -vir 'drive_c/Program Files (x86)/Ubisoft/Ubisoft Game Launcher/savegames' "$uplaybck_folder"
cd "$bck_folder"
echo -ne "./push.sh [y/n]?:"
read aann
if [ "$aann" = "y" ];then
	./push.sh
fi
