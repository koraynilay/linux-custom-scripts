#!/bin/bash
if [ $(date +%H) -lt 20 -a `date +%H` -gt 7 ];then
	rofi_theme=koray.rasi
else
	rofi_theme=koray_dark.rasi
fi
case $1 in
	exit)
		efif="/efi/loader/entries"
		main(){
			entries="terminal\nhtop\nvirtual keyboard\nhibernate\nlogout\nrestart to other kernel\nrestart to windows\nrestart\nshutdown"
			msg="Up: $(uptime -p | awk '{print $2"h "$4"m"}')"
			res=$(echo -e "$entries" | rofi -theme "$rofi_theme" -p "$msg"  -width 10 -xoffset 0 -lines 5 -no-fixed-num-lines -dmenu)

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
					ask "hibernate"
					mpc pause
					systemctl hibernate
					;;
				logout)
					ask "logout"
					i3-msg exit
					;;
				restart\ to\ other\ kernel)
					kerns
					;;
				restart\ to\ windows)
					ask "restart to windows"
					mpc pause
					killall -9 conky
					systemctl reboot --boot-loader-entry=auto-windows
					#dunstify ciao
					;;
				restart)
					ask "restart"
					mpc pause
					killall -9 conky
					systemctl reboot
					;;
				shutdown)
					ask "shutdown"
					mpc pause
					killall -9 conky
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
			res=$(echo -e "${entriesk%\\n}" | rofi -theme "$rofi_theme" -p "$msg"  -width 10 -xoffset 0 -no-fixed-num-lines -dmenu)
			for ((i=0;i<${#array[@]};i++)) do
				if [ "${array[i+1]}" = "$res" ];then
					ask "restart ot other kernel: $(awk '/title/ {$1="";print $0}' "$efif/${array[i]}")"
					killall -9 conky
					systemctl reboot --boot-loader-entry="${array[i]}"
				fi
			done
		}
		ask(){
			res=$(echo -e "Yes\nNo" | rofi -theme "$rofi_theme" -p "Are you sure you want to $@?"  -width 10 -xoffset 0 -lines 2 -no-fixed-num-lines -dmenu)
			#echo $res
			if [ ! "$res" = "Yes" ];then
				exit 1
			fi
		}

		main
		# chrome_tabs_keep shut_pc # Use chtb.sh b
	;;
	run)
		rofi -theme "$rofi_theme" -sidebar-mode -show run
	;;
	show)
		rofi -theme "$rofi_theme" -sidebar-mode -show window
	;;
	*)
		rofi -theme "$rofi_theme" $@
	;;
esac

