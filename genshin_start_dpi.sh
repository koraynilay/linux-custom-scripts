#!/bin/sh
dpi=914
gksudo g203-led dpi $dpi && dunstify "dpi $dpi"
