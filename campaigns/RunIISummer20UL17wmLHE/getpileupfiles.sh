#!/bin/bash
mv pileupinput.dat pileupinput.dat.$(date +"%Y-%m-%d-%H-%M-%S")
dasgoclient -query="file dataset=/Neutrino_E-10_gun/RunIISummer20ULPrePremix-UL17_106X_mc2017_realistic_v6-v3/PREMIX" > pileupinput.dat
