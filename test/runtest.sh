#!/bin/bash
#crun.py test_Bu2PiJpsi2PiMuMu $MYOMCPATH/test/fragment.py RunIIFall18GS \
#    --gfalcp "gsiftp://brux11.hep.brown.edu/mnt/hadoop/store/user/dryu/BParkingMC/test/" \
#    --keepMini \
#    --nevents_job 5 \
#    --njobs 5 \
#    --env

crun.py test_zpqq $MYOMCPATH/test/fragment_zpqq.py RunIISummer20UL17wmLHE \
    --outEOS "/store/user/dryu/DAZSLE/MC/test" \
    --keepMINI \
    --nevents_job 10 \
    --njobs 10 \
    --env
