#!/bin/bash
source env.sh
TOPDIR=$PWD
#CAMPAIGNS=( "RunIIFall18GS" "RunIIFall18GSBParking" "RunIIFall18wmLHEGS" )
CAMPAIGNS=( "RunIISummer20UL16wmLHE" "RunIISummer20UL16APVwmLHE" "RunIISummer20UL17wmLHE" "RunIISummer20UL18wmLHE" "NANOGEN" )
#CAMPAIGNS=( "RunIISummer20UL16wmLHE_pfnano" "RunIISummer20UL16APVwmLHE_pfnano" "RunIISummer20UL17wmLHE_pfnano" "RunIISummer20UL18wmLHE_pfnano" "NANOGEN" )
for CAMPAIGN in "${CAMPAIGNS[@]}"; do
	cd campaigns/$CAMPAIGN
	#source setup_env.sh
	
	if [[ $CAMPAIGN == *"RunIISummer"* ]]; then
		ls -lrth
		cmssw-el7 -- ./setup_env.sh
	elif [[ $CAMPAIGN == *"NANOGEN"* ]]; then
		cmssw-el7 -- ./setup_env.sh
	elif [[ $CAMPAIGN == *"Run3"* ]]; then
		cmssw-el8 -- ./setup_env.sh
	else
		echo "I don't know what OS to use for campaign ${CAMPAIGN}. Please fix firsttime.sh."
		exit 1
	fi
	source getpileupfiles.sh
	cd $TOPDIR
done
