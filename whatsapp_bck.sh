#!/bin/sh
sf="/storage/emulated/0"
wf="WhatsApp"
p="$sf/$wf"

cd $p
tar cvzf WhatsApp.tar.gz "Media/WhatsApp Stickers" Databases/msgstore.db.crypt* Backups
