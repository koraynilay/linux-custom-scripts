#!/bin/bash
if perl -e 'exit ((localtime)[8])' ; then
	#winter (DST off)
	#echo winter
	hs=18 #hour sera
	hm=7  #hour mattina
else
	#summer (DST on)
	#echo summer
	hs=20 #hour sera
	hm=8  #hour mattina
fi
if [ $(date +%H) -lt $hs -a `date +%H` -gt $hm ];then
	rofi_theme=koray.rasi
else
	rofi_theme=koray_dark.rasi
fi
case $1 in
	exit)
		efif="/efi/loader/entries"
		main(){
			entries="terminal\nhtop\nvirtual keyboard\nhibernate\nlogout\nrestart to other kernel\nrestart to firmware\nrestart to windows\nrestart\nshutdown"
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
					if [ "$XDG_SESSION_TYPE" = "wayland" ];then
						swaymsg exit
					else
						i3-msg exit
					fi
					;;
				restart\ to\ other\ kernel)
					kerns
					;;
				restart\ to\ firmware)
					ask "restart"
					mpc pause
					killall -9 conky
					systemctl reboot --firmware-setup
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
	drun)
		rofi -theme "$rofi_theme" -sidebar-mode -show drun
	;;
	show)
		rofi -theme "$rofi_theme" -sidebar-mode -show window
	;;
	*)
		rofi -theme "$rofi_theme" $@
	;;
esac

