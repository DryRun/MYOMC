#!/bin/bash
#crun.py test_Bu2PiJpsi2PiMuMu $MYOMCPATH/test/fragment.py RunIIFall18GS \
#    --gfalcp "gsiftp://brux11.hep.brown.edu/mnt/hadoop/store/user/dryu/BParkingMC/test/" \
#    --keepMini \
#    --nevents_job 5 \
#    --njobs 5 \
#    --env

queue=${1}
if [ -z ${queue} ]; then
    queue=local
fi

if [ "$queue" == "eos" ]; then
    crun.py test_zpqq $MYOMCPATH/test/fragment_zpqq.py RunIISummer20UL17wmLHE \
        --outEOS "/store/user/$USER/PrivateMC/test/" \
        --keepMINI \
        --nevents_job 10 \
        --njobs 10 \
        --env
elif [ "$queue" == "local" ]; then
    crun.py test_zpqq $MYOMCPATH/test/fragment_zpqq.py RunIISummer20UL17wmLHE \
        --keepMINI \
        --nevents_job 10 \
        --njobs 10 \
        --env
fi