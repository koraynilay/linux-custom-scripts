#!/bin/sh
ffmpeg -filter_complex '[1:a][2:a] amerge=inputs=2,pan=stereo|c0<c0+c2|c1<c1+c3[a]'
