#!/bin/sh
dpi=800
gksudo g203-led dpi $dpi && dunstify "dpi $dpi"
