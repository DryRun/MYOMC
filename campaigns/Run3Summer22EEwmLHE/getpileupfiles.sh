#!/bin/bash

if [ -z "$1" ]; then
    CERNNAME=$(whoami)
else
    CERNNAME=$1
fi
echo "[${0}] Using $CERNNAME as username for Rucio"

PILEUP_DATASET="/Neutrino_E-10_gun/Run3Summer21PrePremix-Summer22_124X_mcRun3_2022_realistic_v11-v2/PREMIX"

if [ -f pileupinput.dat ]; then
    mv pileupinput.dat pileupinput.dat.$(date +"%Y-%m-%d-%H-%M-%S")
fi
# dasgoclient -query="file dataset=/Neutrino_E-10_gun/Run3Summer21PrePremix-Summer22_124X_mcRun3_2022_realistic_v11-v2/PREMIX" > pileupinput.dat
get_files_on_disk.py -u ${CERNNAME} -o pileupinput.dat ${PILEUP_DATASET}