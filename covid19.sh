#!/bin/bash
cd $HOME/COVID-19/dati-andamento-nazionale
git pull 2>/dev/null
date="$(date +%Y%m%d)"
datey="$((${date}-1))"
tests=$(tail -qn 1 *${date}.csv *${datey}.csv | rev | cut -d',' -f 3 | rev)
newcases=$(tail -qn 1 *${date}.csv | rev | cut -d',' -f 9 | rev)
testst=${tests%%*$'\n'}
testsy=${tests##*$'\n'}
echo -e "tamponi ${date}: $testst"
echo -e "tamponi ${datey}: $testsy"
newtests=$(calc "$testst-$testsy")
echo -e "nuovi tamponi: $newtests"
echo -e "nuovi tamponi: $newcases"
perc=$(calc "$newcases/$testst*100")
echo -e "perc (full): $perc%"
echo -e "perc: ${perc:1:6}%"
