#!/bin/sh
useradd koray
passwd koray
chown -hR $usernr:$usernr /home/$usernr
su -l $usernr -c "cd ~; chmod +x install_omz.sh; mv ~/$zsh_theme ~/.oh-my-zsh/custom/themes/;exit"

#plip
#useradd koray
#oasswd koray
#chown -hR koray:koray /home/koray #need numbers, like this doesn't work in bash it seems
#chmod +x /home/koray/install_omz.sh
#su -l koray -c "cd ~;./install_omz.sh;mv ~/kora.zsh-theme ~/.oh-my-zsh/custom/themes/;exit"
