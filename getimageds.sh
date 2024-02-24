#!/bin/zsh
base_url="https://cdn.discordapp.com/attachments"
DS_EPOCH=1420070400000
st=1707225874272
end=1707225752102
channel=1203542823425544243
img="DSC_0983.JPG"
spoiler=1
mkdir "${channel}_outs"
cd "${channel}_outs"
[ $spoiler -eq 1 ] && img="SPOILER_$img"
for a in {$st..$end};do
	timestamp=`calc -p "$a-$DS_EPOCH"`
	tsb=`python -c "print(bin($timestamp))"`
	for i in {0..100};do
		last=`python -c "print(format($i, 'b').zfill(22))"`
		finbin="$tsb$last"
		findec=`calc -p "$finbin"`
		echo $a:$finbin:$findec
		curl "$base_url/$channel/$findec/$img" --output "${findec}_$img"
	done       
done
# https://cdn.discordapp.com/attachments/1203542823425544243/1204228020425068584/image.png
