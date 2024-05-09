#!/bin/bash
source env.sh
TOPDIR=$PWD
#CAMPAIGNS=( "RunIIFall18GS" "RunIIFall18GSBParking" "RunIIFall18wmLHEGS" )
CAMPAIGNS=( "RunIISummer20UL16wmLHE" "RunIISummer20UL16APVwmLHE" "RunIISummer20UL17wmLHE" "RunIISummer20UL18wmLHE" "NANOGEN" )
#CAMPAIGNS=( "RunIISummer20UL16wmLHE_pfnano" "RunIISummer20UL16APVwmLHE_pfnano" "RunIISummer20UL17wmLHE_pfnano" "RunIISummer20UL18wmLHE_pfnano" "NANOGEN" )
for CAMPAIGN in "${CAMPAIGNS[@]}"; do
	cd campaigns/$CAMPAIGN
	source setup_env.sh
	source getpileupfiles.sh
	cd $TOPDIR
done
