#!/bin/bash
source env.sh
TOPDIR=$PWD
CAMPAIGNS=( "RunIIFall18GS" "RunIIFall18GSBParking" "RunIIFall18wmLHEGS" )
for CAMPAIGN in "${CAMPAIGNS[@]}"; do
	cd $CAMPAIGN
	source setup_env.sh
	cd $TOPDIR
done
