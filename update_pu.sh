#!/bin/bash
if [ -z ${MYOMCPATH+x} ]; then
	source $PWD/env.sh
fi
# voms-proxy-init -voms cms
TOPDIR=$PWD
#CAMPAIGNS=( "RunIIFall18GS" "RunIIFall18GSBParking" "RunIIFall18wmLHEGS" )
# CAMPAIGNS=( "RunIISummer20UL16wmLHE" "RunIISummer20UL16APVwmLHE" "RunIISummer20UL17wmLHE" "RunIISummer20UL18wmLHE" "NANOGEN" )
CAMPAIGNS=( "Run3Summer22wmLHE" "Run3Summer22EEwmLHE" "Run3Summer23wmLHE" "Run3Summer23BPixwmLHE" )

if [ -z "$1" ]; then
    CERNNAME=$(whoami)
    echo "Using current username (${CERNNAME}) as CERN username"
    echo " "
    echo " "
    CERNNAME=$(whoami)
else
    CERNNAME=$1
fi

for CAMPAIGN in "${CAMPAIGNS[@]}"; do
	cd campaigns/$CAMPAIGN
    if [ -e "getpileupfiles.sh" ]; then
		source getpileupfiles.sh ${CERNNAME}
	fi
	cd $TOPDIR
done