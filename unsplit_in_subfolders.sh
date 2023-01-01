#!/bin/sh
# `forf ../sus` simply runs the command provided as argument on each line ($line) of ../sus
# (check my .zsh_custom/.envzsh in my dotfiles-term repo)
forf ../sus 'cd "$line";
		miao=$(basename $line);
		mi=${miao%.*};
		echo mi:$mi;
		if ! [ -f "$mi" ];then
			du -hs
			echo -n doing...
			cat * > "$mi".tmp
			mv "$mi".tmp "$mi"
			echo done
			du -h "$mi"
			file "$mi"
		else
			du -hs
			echo not doing, already exists:
			du -h "$mi"
			file "$mi"
		fi
		cd /backups/degoo_jd/Shadowplay/Videos'
