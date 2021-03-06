#!/bin/bash
efif="/efi/loader/entries"
main(){
	entries="terminal\nhtop\nvirtual keyboard\nhibernate\nlogout\nrestart to other kernel\nrestart to windows\nrestart\nshutdown"
	msg="Up: $(uptime -p | awk '{print $2"h "$4"m"}')"
	res=$(echo -e "$entries" | rofi -p "$msg"  -width 10 -xoffset 0 -lines 5 -no-fixed-num-lines -dmenu)

	case $res in
		terminal)
			termite
			;;
		htop)
			termite -e htop
			;;
		virtual\ keyboard)
			onboard
			;;
		hibernate)
			ask
			mpc pause
			systemctl hibernate
			;;
		logout)
			ask
			i3-msg exit
			;;
		restart\ to\ other\ kernel)
			kerns
			;;
		restart\ to\ windows)
			ask
			mpc pause
			systemctl reboot --boot-loader-entry=auto-windows
			#dunstify ciao
			;;
		restart)
			ask
			mpc pause
			systemctl reboot
			;;
		shutdown)
			ask
			mpc pause
			systemctl poweroff
			;;
	esac
}
kerns(){
	entriesk=""
	array=()
	for file in $efif/*;do
		c=$(awk '/title/ {$1="";print $0}' "$file")
		array+=("$(basename "$file")")
		array+=("${c#\ }")
		entriesk+="${c#\ }\n"
	done
	#echo -ne $entriesk
	#echo ${array[@]}
	msg="Up: $(uptime -p | awk '{print $2"h "$4"m"}')"
	res=$(echo -e "${entriesk%\\n}" | rofi -p "$msg"  -width 10 -xoffset 0 -no-fixed-num-lines -dmenu)
	for ((i=0;i<${#array[@]};i++)) do
		if [ "${array[i+1]}" = "$res" ];then
			ask
			systemctl reboot --boot-loader-entry="${array[i]}"
		fi
	done
}
ask(){
	res=$(echo -e "Yes\nNo" | rofi -p "Are you sure?"  -width 10 -xoffset 0 -lines 2 -no-fixed-num-lines -dmenu)
	#echo $res
	if [ ! "$res" = "Yes" ];then
		exit 1
	fi
}

main
# chrome_tabs_keep shut_pc # Use chtb.sh b
