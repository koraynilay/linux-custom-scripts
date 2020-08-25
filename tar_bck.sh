#!/bin/sh
folders=$('/usr' '/var' '/opt' '/etc' '/root')
exfolders=$(${folders[@]} '/swpfl.sys')
#tar --one-file-system --exclude=/etc --exclude=/opt --exclude=/root --exclude=/usr --exclude=/var --exclude=/swpfl.sys --acls --xattrs -czpvf /D/linux/tars/r.tar.gz /
echo "$folders"
echo "$exfolders"
