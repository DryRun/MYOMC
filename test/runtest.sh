#!/bin/bash
#crun.py test_Bu2PiJpsi2PiMuMu $MYOMCPATH/test/fragment.py RunIIFall18GS \
#    --gfalcp "gsiftp://brux11.hep.brown.edu/mnt/hadoop/store/user/dryu/BParkingMC/test/" \
#    --keepMini \
#    --nevents_job 5 \
#    --njobs 5 \
#    --env

QUEUE=${1}
if [ -z ${QUEUE} ]; then
    QUEUE=local
fi

#CAMPAIGNS=( "RunIISummer20UL16wmLHE" "RunIISummer20UL16APVwmLHE" "RunIISummer20UL17wmLHE" "RunIISummer20UL18wmLHE" )
CAMPAIGNS=( "RunIISummer20UL18wmLHE" )

if [ "$QUEUE" == "condor" ]; then
    for CAMPAIGN in "${CAMPAIGNS[@]}"; do
        crun.py test_zpqq $MYOMCPATH/test/fragment_zpqq.py ${CAMPAIGN} \
            --outEOS "/store/user/$USER/MYOMC/test/${CAMPAIGN}" \
            --keepMINI \
            --keepNANO \
            --nevents_job 10 \
            --njobs 10 \
            --env \
            --overwrite
    done
elif [ "$QUEUE" == "condor_eos" ]; then
    crun.py test_zpqq $MYOMCPATH/test/fragment_zpqq.py RunIISummer20UL17wmLHE \
        --keepMINI \
        --keepNANO \
        --nevents_job 10 \
        --njobs 10 \
        --env
elif [ "$QUEUE" == "local" ]; then
    STARTDIR=$PWD
    mkdir testjob
    cd testjob
    source "$STARTDIR/../RunIISummer20UL17wmLHE/run.sh" test "$STARTDIR/fragment_zpqq.py" 10 1 1 "$STARTDIR/../RunIISummer20UL17wmLHE/pileupinput.dat"
    # Args are: name fragment_path nevents random_seed nthreads pileup_filelist
    cd $STARTDIR
fi