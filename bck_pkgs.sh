#!/bin/sh
pacman -Qqen >> pkglist.txt
pacman -Qqem >> pkglist_aur.txt
