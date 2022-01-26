#!/bin/bash
# Some old stuff to ensure this is run on SLC6
#export SYSTEM_RELEASE=`cat /etc/redhat-release`
#if { [[ $SYSTEM_RELEASE == *"release 7"* ]]; }; then
#  echo "Running setup_env.sh on SLC6."
#  if { [[ $(hostname -s) = lxplus* ]]; }; then
#  	ssh -Y lxplus6 "cd $PWD; source setup_env.sh;"
#  elif { [[ $(hostname -s) = cmslpc* ]]; }; then
#  	ssh -Y cmslpc-sl6 "cd $PWD; source setup_env.sh;"
#  else
#  	echo "Not on cmslpc or lxplus, not sure what to do."
#  	return 1
#  fi
#  return 1
#fi

mkdir env
cd env
export SCRAM_ARCH=slc7_amd64_gcc700
source /cvmfs/cms.cern.ch/cmsset_default.sh

scram project -n "CMSSW_10_6_28_patch1" CMSSW_10_6_28_patch1
cd CMSSW_10_6_28_patch1/src
eval `scram runtime -sh`
scram b
cd ../..


scram project -n "CMSSW_10_6_17_patch1" CMSSW_10_6_17_patch1
cd CMSSW_10_6_17_patch1/src
eval `scram runtime -sh`
scram b
cd ../../

scram project -n "CMSSW_10_2_16_UL" CMSSW_10_2_16_UL
cd CMSSW_10_2_16_UL/src
eval `scram runtime -sh`
scram b
cd ../../

scram project -n "CMSSW_10_6_25" CMSSW_10_6_25
cd CMSSW_10_6_25/src
eval `scram runtime -sh`
scram b
cd ../../

tar -czvf env.tar.gz ./CMSSW*
mv env.tar.gz ..
cd ..
