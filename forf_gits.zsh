#!/bin/zsh
forf () {
	OFS=$IFS 
	IFS=$'\n' 
	[[ -z $1 ]] && echo -e "Usage: $0 [q (optional)] [file] [cmd]" && return 1
	file_arg=1 
	cmd_arg=2 
	echo=1 
	if [ "$1" = "q" ]
	then
		echo=0 
		file_arg=2 
		cmd_arg=3 
	fi
	for line in $(cat "${(P)file_arg}")
	do
		if [ $echo -eq 1 ]
		then
			echo $line
		fi
		eval "${(P)cmd_arg}"
	done
	IFS=$OFS 
}

forf q .zsh_gits 'line_trimmed=$(echo $line | cut -f 1 -d'=');tocd=${(P)line_trimmed};
		if [[ ! "$tocd" =~ ^[0-9]$ ]];then
			cd "$tocd";
			gst=$(git status --porcelain);
			if [ -n "$gst" ];then
				echo $tocd;
				echo $gst;
				echo
			fi;
		fi;cd ~;' > list_status_gits.txt

