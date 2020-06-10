#!/bin/sh
useradd koray
passwd koray
chown -hR $usernr:$usernr /home/$usernr
su -l $usernr -c "cd ~; chmod +x install_omz.sh; mv ~/$zsh_theme ~/.oh-my-zsh/custom/themes/;exit"
