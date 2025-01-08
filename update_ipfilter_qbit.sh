#!/bin/bash
url="https://github.com/DavidMoore/ipfilter/releases/download/lists/ipfilter.dat"
o="$HOME/ipfilter.dat"
curl -L "$url" -o "$o"
