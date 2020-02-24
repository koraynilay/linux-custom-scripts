#!/bin/sh
abc=$(curl --output - https://www.who.int/docs/default-source/coronaviruse/situation-reports/20200223-sitrep-34-covid-19.pdf 2>/dev/null | grep "This Page cannot be found")
if [ -z $abc ];then
	echo $abc
	dunstify -u C -t 999999999 "new COVID-19 Report"
fi
