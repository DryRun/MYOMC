#!/bin/bash
mv pileupinput.dat pileupinput.dat.$(date +"%Y-%m-%d-%H-%M-%S")
dasgoclient -query="file dataset=/Neutrino_E-10_gun/Run3Summer21PrePremix-Summer23_130X_mcRun3_2023_realistic_v13-v1/PREMIX" > pileupinput.dat