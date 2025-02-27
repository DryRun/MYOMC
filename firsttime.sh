#!/bin/bash
if [ -z ${MYOMCPATH+x} ]; then
	source env.sh
fi
# voms-proxy-init -voms cms
TOPDIR=$PWD
#CAMPAIGNS=( "RunIIFall18GS" "RunIIFall18GSBParking" "RunIIFall18wmLHEGS" )
# CAMPAIGNS=( "RunIISummer20UL16wmLHE" "RunIISummer20UL16APVwmLHE" "RunIISummer20UL17wmLHE" "RunIISummer20UL18wmLHE" "NANOGEN" )
CAMPAIGNS=( "Run3Summer22wmLHE" "Run3Summer22EEwmLHE" "Run3Summer23wmLHE" "Run3Summer23BPixwmLHE" )
#CAMPAIGNS=( "RunIISummer20UL16wmLHE_pfnano" "RunIISummer20UL16APVwmLHE_pfnano" "RunIISummer20UL17wmLHE_pfnano" "RunIISummer20UL18wmLHE_pfnano" "NANOGEN" )

#check is the host is cmslpc or lxplus
if [[ $HOSTNAME == *"lpc"* ]]; then
	echo "You are on cmslpc. Setting up the environment."
elif [[ $HOSTNAME == *"lxplus"* ]]; then
	echo "You are on lxplus. Setting up the environment."
else
	echo "I don't know what host you are on, using lxplus settings"
	exit 1
fi

for CAMPAIGN in "${CAMPAIGNS[@]}"; do
	cd campaigns/$CAMPAIGN
	#Print files in the directory
	ls	
	if [[ $CAMPAIGN == *"RunIISummer"* ]]; then
		if [[ $HOSTNAME == *"lpc"* ]]; then
			cmssw-el7 -p --bind `readlink $HOME` --bind `readlink -f ${HOME}/nobackup/` --bind /uscms_data --bind /cvmfs -- ./setup_env.sh
		else
			cmssw-el7 -p --bind `readlink -f ${PWD}` --bind `readlink -f $HOME/private` -- ./setup_env.sh
		fi
	elif [[ $CAMPAIGN == *"NANOGEN"* ]]; then
		if [[ $HOSTNAME == *"lpc"* ]]; then
			cmssw-el7 -p --bind `readlink $HOME` --bind `readlink -f ${HOME}/nobackup/` --bind /uscms_data --bind /cvmfs -- ./setup_env.sh
		else
			cmssw-el7 -p --bind `readlink -f ${PWD}` --bind `readlink -f $HOME/private` -- ./setup_env.sh
		fi
	elif [[ $CAMPAIGN == *"Run3"* ]]; then
		if [[ $HOSTNAME == *"lpc"* ]]; then
			cmssw-el8 -p --bind `readlink $HOME` --bind `readlink -f ${HOME}/nobackup/` --bind /uscms_data --bind /cvmfs -- ./setup_env.sh
		else
			cmssw-el8 -p --bind `readlink -f ${PWD}` --bind `readlink -f $HOME/private` -- ./setup_env.sh
		fi
	else
		echo "I don't know what OS to use for campaign ${CAMPAIGN}. Please fix firsttime.sh."
		exit 1
	fi
	if [ -e "getpileupfiles.sh" ]; then
		source getpileupfiles.sh
	fi
	cd $TOPDIR
done
