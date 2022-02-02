#!/bin/bash
#set -x
#set -e
#set -n
#set -v
echo=""
#echo="echo"
m=(
	"ser"
	"tpsi"
	"tele"
	"ita"
)
c="4D"
f=(
	"/home/koraynilay/lns/grassi/sistemi_e_reti/$c"
	"/home/koraynilay/lns/grassi/tpsi/$c"
	"/home/koraynilay/lns/grassi/telecomunicazioni/$c"
	"/home/koraynilay/lns/grassi/italiano/$c"
)
o=""
ot=""
for ((i=0;i<${#f[@]};i++)) do
	cd "${f[i]}"
	#cat *.txt > ../${m[i]}.txt
	for k in appunti_*.txt; do
		echo -en "\n$k\n" >> ../${m[i]}_appunti.txt
		cat "$k" >> ../${m[i]}_compiti.txt
	done
	for k in compiti_*.txt; do
		echo -en "\n$k\n" >> ../${m[i]}_appunti.txt
		cat "$k" >> ../${m[i]}_compiti.txt
	done
	cd ..
	zip -r "${m[i]}.zip" "$c" "${m[i]}_appunti.txt" "${m[i]}_compiti.txt"
	 o+="${f[i]}/../${m[i]}.zip "
	ot+="${f[i]}/../${m[i]}_appunti.txt "
	ot+="${f[i]}/../${m[i]}_compiti.txt "
done
echo $o $ot
dragon-drag-and-drop $o
#read
rm -v $o $ot
