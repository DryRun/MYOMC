#!/bin/bash

if [ -z "$1" ]; then
    CERNNAME=$(whoami)
else
    CERNNAME=$1
fi
echo "[${0}] Using ${CERNNAME} as username for Rucio"

# NOTE: This script is for the Run3Summer24 campaign and intentionally uses the
# RunIIISummer24 PrePremix premix library:
#   Premixlib2024_140X_mcRun3_2024_realistic_v26-v1
# This differs from the older/default Summer23_130X_mcRun3_2023_realistic_v13-v1
# pileup dataset referenced in run.sh.
PILEUP_DATASET="/Neutrino_E-10_gun/RunIIISummer24PrePremix-Premixlib2024_140X_mcRun3_2024_realistic_v26-v1/PREMIX"

if [ -f pileupinput.dat ]; then
    mv pileupinput.dat pileupinput.dat.$(date +"%Y-%m-%d-%H-%M-%S")
fi
# dasgoclient -query="file dataset=/Neutrino_E-10_gun/Run3Summer21PrePremix-Summer22_124X_mcRun3_2022_realistic_v11-v2/PREMIX" > pileupinput.dat
get_files_on_disk.py -u ${CERNNAME} -o pileupinput.dat ${PILEUP_DATASET}
