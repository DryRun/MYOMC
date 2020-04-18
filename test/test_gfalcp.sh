#!/bin/bash
touch test.root
for FILENAME in ./*root; do
    echo "\"Copying $FILENAME\""
    gfal-copy -p -v -t 180 file://$PWD/$FILENAME 'gsiftp://brux11.hep.brown.edu/mnt/hadoop/store/user/dryu/BParkingMC/test/'
done

