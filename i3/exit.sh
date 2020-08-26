#!/bin/bash
efif="/efi/loader/entries"
main(){
	entries="terminal\nhtop\nhibernate\nlogout\nrestart to other kernel\nrestart to windows\nrestart\nshutdown"
	msg="Up: $(uptime -p | awk '{print $2"h "$4"m"}')"
	res=$(echo -e "$entries" | rofi -p "$msg"  -width 10 -xoffset 0 -lines 5 -no-fixed-num-lines -dmenu)

	case $res in
		terminal)
			termite
			;;
		htop)
			termite -e htop
			;;
		hibernate)
			mpc pause
			systemctl hibernate
			;;
		logout)
			i3-msg exit
			;;
		restart\ to\ other\ kernel)
			kerns
			;;
		restart\ to\ windows)
			mpc pause
			systemctl reboot --boot-loader-entry=auto-windows
			#dunstify ciao
			;;
		restart)
			mpc pause
			systemctl reboot
			;;
		shutdown)
			mpc pause
			systemctl poweroff
			;;
	esac
}
kerns(){
	entriesk=""
	r=""
	for file in $efif/*;do
		r+=$(basename "$file")
		c=$(awk '/title/ {$1="";print $0}' "$file")
		entriesk+="${c/\ }\n"
		#entriesk+="$(basename ${file%.conf})\n"
	done
	echo -ne $entriesk
	msg="Up: $(uptime -p | awk '{print $2"h "$4"m"}')"
	res=$(echo -e "${entriesk%\\n}" | rofi -p "$msg"  -width 10 -xoffset 0 -no-fixed-num-lines -dmenu)
	IFS=$'\n'
	for en in $r;do
		if [ "$en" = "$res" ];then
			systemctl reboot --boot-loader-entry="$en"
		fi
	done
}

main
# chrome_tabs_keep shut_pc # Use chtb.sh b
