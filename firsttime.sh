#!/bin/bash
if [ -z ${MYOMCPATH+x} ]; then
	source env.sh
fi
voms-proxy-init -voms cms
TOPDIR=$PWD
#CAMPAIGNS=( "RunIIFall18GS" "RunIIFall18GSBParking" "RunIIFall18wmLHEGS" )
CAMPAIGNS=( "RunIISummer20UL16wmLHE" "RunIISummer20UL16APVwmLHE" "RunIISummer20UL17wmLHE" "RunIISummer20UL18wmLHE" "NANOGEN" )
#CAMPAIGNS=( "RunIISummer20UL16wmLHE_pfnano" "RunIISummer20UL16APVwmLHE_pfnano" "RunIISummer20UL17wmLHE_pfnano" "RunIISummer20UL18wmLHE_pfnano" "NANOGEN" )
for CAMPAIGN in "${CAMPAIGNS[@]}"; do
	cd campaigns/$CAMPAIGN	
	if [[ $CAMPAIGN == *"RunIISummer"* ]]; then
		cmssw-el7 -p --bind `readlink -f ${PWD}` --bind `readlink $HOME/private` -- ./setup_env.sh
	elif [[ $CAMPAIGN == *"NANOGEN"* ]]; then
		cmssw-el7 -p --bind `readlink -f ${PWD}` --bind `readlink $HOME/private` -- ./setup_env.sh
	elif [[ $CAMPAIGN == *"Run3"* ]]; then
		cmssw-el8 -p --bind `readlink -f ${PWD}` --bind `readlink $HOME/private` -- ./setup_env.sh
	else
		echo "I don't know what OS to use for campaign ${CAMPAIGN}. Please fix firsttime.sh."
		exit 1
	fi
	source getpileupfiles.sh
	cd $TOPDIR
done
