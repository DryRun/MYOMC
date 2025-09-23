#!/bin/bash
if [ -f pileupinput.dat ]; then
	mv pileupinput.dat pileupinput.dat.$(date +"%Y-%m-%d-%H-%M-%S")
fi
dasgoclient -query="file dataset=/Neutrino_E-10_gun/RunIISummer20ULPrePremix-UL18_106X_upgrade2018_realistic_v11_L1v1-v2/PREMIX" > pileupinput.dat
