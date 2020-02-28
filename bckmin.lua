#!/bin/lua
config_folder_path = "/root/"
destination = config_folder_path.."dotfiles-minimal"
folders = {
-- .config folder
	config_folder_path..".config/i3",
	config_folder_path..".config/picom.conf",
	config_folder_path..".config/picom_launch.sh",
	
	config_folder_path..".config/polybar",
	config_folder_path..".config/termite",
	config_folder_path..".config/dunst",

	config_folder_path..".config/htop",
	config_folder_path..".config/neofetch",
	config_folder_path..".config/cava",
	config_folder_path..".config/peaclock",
	
	config_folder_path..".config/mpd",
	config_folder_path..".config/rofi",
	config_folder_path..".config/ranger",
	config_folder_path..".config/SpeedCrunch",
	
	config_folder_path..".config/kdeconnect",
	config_folder_path..".config/systemd",
	
	config_folder_path..".config/ferdi-themes",
	config_folder_path..".config/herbstluftwm",
	config_folder_path..".config/leafpad",
	config_folder_path..".config/shalarm",
	config_folder_path..".config/viewnior/viewnior.conf",
	config_folder_path..".config/gtk-3.0/settings.ini",

	config_folder_path..".config/gzdoom/gzdoom.ini",
	config_folder_path..".config/gzdoom/saves",
	config_folder_path..".config/google-chrome/configs",
	config_folder_path..".config/user-dirs.dirs",
	config_folder_path..".config/user-dirs.locale",
-- home folder
	config_folder_path..".ashrc",
	config_folder_path..".assaultcube",
	config_folder_path..".bash_history",
	config_folder_path..".fehbg",
	config_folder_path..".gtkrc-2.0",
	config_folder_path..".ideskrc",
	config_folder_path..".idesktop",
	config_folder_path..".kde4",
	config_folder_path..".lesshst",
	config_folder_path..".ncmpcpp",
	config_folder_path..".node_repl_history",
	config_folder_path..".python_history",
	config_folder_path..".radare2rc",
	-- vim
	config_folder_path..".vim",
	config_folder_path..".vimrc",
	config_folder_path..".viminfo",
	-- xorg
	config_folder_path..".xinitrc",
	config_folder_path..".Xmodmap",
	-- zsh
	config_folder_path..".zshrc",
	config_folder_path..".zsh_history",
	config_folder_path..".oh-my-zsh/custom",

	config_folder_path..".local/share/SpeedCrunch"
};

if not os.execute("ls "..destination.." >/dev/null 2>&1") then
	print("Destination folder ("..destination..") doesn't exist, create it or cancel? [y/n]: ");
	ans=io.read()
	if ans == "yes" or ans == "y" then
		os.execute("mkdir -vp "..destination)
	else
		os.exit(1);
	end
end
for number,folder in pairs(folders) do
	config_folder = string.find(folder, "config");
	if not config_folder then
		dest = destination.."/"
	else
		dest = destination.."/config/"
	end
	print("copying "..folder.." to "..dest.."...");
	exitcp=os.execute("cp -r \""..folder.."\" \""..dest.."\"");
	--[[if not exitcp then
		print("cp exited with an error.\nContinue anyway? [y/n]: ")
		ans=io.read()
		if not (ans == "yes" or ans == "y") then
			os.exit(1);
		end
	end]]
end
os.execute([[
	   cd "]]..destination..[[";
	   for file in $(find . -name ".git");do
		if [ $file = "./.git" ];then
			continue;
		fi;
	   	echo removing $file...;
		rm -rf $file;
	   done
	   ]]);
--	print(a);
--	os.execute();
