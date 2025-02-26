#!/bin/bash
mv pileupinput.dat pileupinput.dat.$(date +"%Y-%m-%d-%H-%M-%S")
dasgoclient -query="file dataset=/Neutrino_E-10_gun/Run3Summer21PrePremix-Summer22_124X_mcRun3_2022_realistic_v11-v2/PREMIX" > pileupinput.dat
