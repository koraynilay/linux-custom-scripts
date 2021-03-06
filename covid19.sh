#!/bin/bash
cd $HOME/COVID-19/dati-andamento-nazionale
git pull 2>&1 | tail -1
#[[ $? -ne 0 ]] && exit $?
date="$(date +%Y%m%d)"
#date="$(($(date +%Y%m%d)-1))"
datey="$(date +%Y%m%d --date="-1 day")"
#datey="$((${date}-1))"
tests=$(tail -qn 1 *${date}.csv *${datey}.csv | rev | cut -d',' -f 3 | rev)
newcases=$(tail -qn 1 *${date}.csv | rev | cut -d',' -f 9 | rev)
testst=$(echo $tests | awk '{print $1}')
testsy=$(echo $tests | awk '{print $2}')
echo -e "tamponi ${date}: $testst"
echo -e "tamponi ${datey}: $testsy"
newtests=$(calc -d -p "$testst-$testsy")
echo -e "nuovi tamponi: $newtests"
echo -e "nuovi casi: $newcases"
perc=$(calc -d -p "$newcases/$newtests*100")
echo -e "perc (full): $perc%"
percs=${perc:0:9}%
echo -e "perc: $percs"
end="$newcases nuovi casi, $percs dei $newtests nuovi tamponi"
echo -e $end
echo -ne $end | xclip -selection clipboard

#https://raw.githubusercontent.com/pcm-dpc/COVID-19/master/dati-andamento-nazionale/dpc-covid19-ita-andamento-nazionale-20201117.csv
