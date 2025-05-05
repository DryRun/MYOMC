#!/bin/bash

if [ -z "$1" ]; then
    CERNNAME=$(whoami)
    echo "Using current username (${CERNNAME}) as CERN username"
    echo " "
    echo " "
    CERNNAME=$(whoami)
else
    CERNNAME=$1
fi

mv pileupinput.dat pileupinput.dat.$(date +"%Y-%m-%d-%H-%M-%S")
# dasgoclient -query="file dataset=/Neutrino_E-10_gun/Run3Summer21PrePremix-Summer22_124X_mcRun3_2022_realistic_v11-v2/PREMIX" > pileupinput.dat
python3 ../../utils/get_files_on_disk.py -u ${CERNNAME} -o pileupinput.dat /Neutrino_E-10_gun/Run3Summer21PrePremix-Summer23_130X_mcRun3_2023_realistic_v13-v1/PREMIX