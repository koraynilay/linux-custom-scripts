#!/bin/bash
#set -x
#set -e
#set -n
#set -v
echo=""
#echo="echo"
m=(
	#"ser"
	"informatica"
	#"tpsi"
	#"tele"
	#"ita"
)
c="5D"
f=(
	#"/home/koraynilay/lns/grassi/sistemi_e_reti/$c"
	"/home/koraynilay/lns/grassi/informatica/$c"
	#"/home/koraynilay/lns/grassi/tpsi/$c"
	#"/home/koraynilay/lns/grassi/telecomunicazioni/$c"
	#"/home/koraynilay/lns/grassi/italiano/$c"
)
o=""
ot=""
for ((i=0;i<${#f[@]};i++)) do
	cd "${f[i]}"
	#cat *.txt > ../${m[i]}.txt
	for k in appunti_*.txt; do
		echo -en "\n$k\n" >> ../${m[i]}_appunti.txt
		cat "$k" >> ../${m[i]}_appunti.txt
	done
	for k2 in compiti_*.txt; do
		echo -en "\n$k2\n" >> ../${m[i]}_compiti.txt
		cat "$k2" >> ../${m[i]}_compiti.txt
	done
	cd ..
	zip -r "${m[i]}.zip" "$c" "${m[i]}_appunti.txt" "${m[i]}_compiti.txt"
	 o+="${f[i]}/../${m[i]}.zip "
	ot+="${f[i]}/../${m[i]}_appunti.txt "
	ot+="${f[i]}/../${m[i]}_compiti.txt "
done
echo $o $ot
dragon-drop $o
#read
rm -v $o $ot
