#!/bin/bash
#export SYSTEM_RELEASE=`cat /etc/redhat-release`
#if { [[ $SYSTEM_RELEASE == *"release 7"* ]]; }; then
#  echo "Running setup_env.sh on SLC6."
#  if { [[ $(hostname -s) = lxplus* ]]; }; then
#  	ssh -Y lxplus6 "cd $PWD; source setup_env.sh;"
#  elif { [[ $(hostname -s) = cmslpc* ]]; }; then
#    #ssh -Y cmslpc-sl6 "cd $PWD; source setup_env.sh;"
#    ssh -Y cmslpc23 "cd $PWD; source setup_env.sh;"
#  else
#  	echo "Not on cmslpc or lxplus, not sure what to do."
#  	return 1
#  fi
#  return 1
#fi

if [ -d env ]; then
	rm -rf env
fi

mkdir -pv env
cd env
source /cvmfs/cms.cern.ch/cmsset_default.sh

#export SCRAM_ARCH=slc6_amd64_gcc700
scram project -n "CMSSW_10_6_32_patch1" CMSSW_10_6_32_patch1
cd CMSSW_10_6_32_patch1/src
eval `scram runtime -sh`
#git cms-init
#git cms-merge-topic DryRun:CMSSW_10_6_22_NANOGEN-NANOGEN
scram b
cd ../../

tar -czf env.tar.gz ./CMSSW*
mv env.tar.gz ..
cd ..

