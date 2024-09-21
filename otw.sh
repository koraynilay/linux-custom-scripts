#!/bin/bash
# OverTheWire wargames (https://overthewire.org/wargames) helper

printhelp() {
	echo -ne "Usage: $0 [wargame name] [opt]\n";
	echo -ne "  -p\tSpecify the port, it can be used instead of the name or to specify a different port\n";
	echo -ne "  -l\tList supported wargames"
	echo
	exit 0
}

listwargames() {
	for game in "${!wargames[@]}"; do
		echo "$game (port ${wargames[$game]})"
	done
	exit 0
}

declare -A wargames
wargames=(
	['bandit']='2220'
	['leviathan']='2223'
	['natas']='none' # http://natasX.natas.labs.overthewire.org where X is the level
	['krypton']='2231'
	['narnia']='2226'
	['behemoth']='2221'
	['utumno']='2227'
	['maze']='2225'
	['vortex']='2228'
	['manpage']='2224'
	['drifter']='2230'
	['formulaone']='2232'
)

OPTS="hlp:"

getopt --test
if [ "$?" -eq 4 ];then
	set -- $(getopt --options="$OPTS" --name "$0" -- "$@")
fi

while getopts "$OPTS" opt;do #r #per -r (resume)
	case $opt in
		p)wargameport="$OPTARG";;
		h)printhelp;;
		l)listwargames;;
		?)exit 2;;
	esac
done

if [ -z "$1" ];then
	echo "$0: missing wargame argument"
	echo "Try '$0 -h' for more information"
fi

wargame="$1"
wargameport="${wargames[$wargame]}"

n=0 #TODO: start at last available password
while true; do
	wargameuser="$wargame$n"
	wargamedomain="$wargame.labs.overthewire.org"

	read -rp "type password for $wargameuser: " pass
	echo "$pass" > "$wargameuser/$filepassname"

	echo "connecting to $wargame with user $wargameuser"
	sshpass -f"$wargameuser/$filepassname" ssh "$wargameuser@$wargamedomain" -p "$wargameport"

	n=$((n+1))
done





#if [ -z "$1" ];then
#	read -rp "type wargame name: " wargame
#else
#	wargame="$1"
#fi
