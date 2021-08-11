#!/bin/bash
#from https://www.unix.com/linux/176239-viewing-progress-diff.html
cd "$1"
export DEST="$2"
cnt=0
for fname in *
do
    old=$(cksum $fname )
    old=${old%% *}
    new=$(cksum $DEST/${fname})
    new=${new%% *}
    cnt=$(( $cnt +  1 ))
    [ $(( $cnt % 5 )) -eq 0 ] && echo "$cnt files processed"
    [ "$old" = "$new" ] && continue  
    echo "failure on file $fname"
done
