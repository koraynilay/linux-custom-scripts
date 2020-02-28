#!/bin/lua
home_folder = "/root/"
dest_basename= "dotfiles-full"
destination = home_folder..dest_basename
if not os.execute("ls "..destination.." >/dev/null 2>&1") then
	print("Destination folder ("..destination..") doesn't exist, create it or cancel? [y/n]: ");
	ans=io.read()
	if ans == "yes" or ans == "y" then
		os.execute("mkdir -vp "..destination)
	else
		os.exit(1);
	end
end
print("copying "..home_folder.." to "..destination);
os.execute("cd \""..home_folder.."\"; cp -rf $(ls -a \""..home_folder.."\" | grep -v '"..dest_basename.."' | awk '/.../') \""..destination.."\"");
os.execute("rm -rf "..destination.."/.cache");
os.execute("rm -rf "..destination.."/.mozilla");
os.execute("rm -rf "..destination.."/.config/google-chrome");
os.execute("rm -rf "..destination.."/.config/chromium");
os.execute("rm -rf "..destination.."/.config/discord");
os.execute("rm -rf "..destination.."/.config/unity3d");
os.execute("rm -rf "..destination.."/.config/UnityHub");
os.execute("rm -rf "..destination.."/.config/Ferdi");
os.execute("rm -rf "..destination.."/.local/share/Steam");
os.execute("rm -rf "..destination.."/.local/share/Trash");
os.execute("rm -rf "..destination.."/dotfiles-minimal");
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
