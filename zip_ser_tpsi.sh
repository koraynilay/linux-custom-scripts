#!/bin/bash
echo=""
#echo="echo"
m=("ser" "tpsi")
c="4D"
f=("/home/koraynilay/lns/grassi/sistemi_e_reti/$c" "/home/koraynilay/lns/grassi/tpsi/$c")
o=""
ot=""
for ((i=0;i<${#f[@]};i++)) do
	$echo cd "${f[i]}"
	$echo cat *.txt > ../${m[i]}.txt
	$echo cd ..
	$echo zip -r "${m[i]}.zip" "$c" "${m[i]}.txt"
	 o+="${f[i]}/../${m[i]}.zip "
	ot+="${f[i]}/../${m[i]}.txt "
done
echo $o $ot
dragon-drag-and-drop -a $o
rm -v $o $ot
