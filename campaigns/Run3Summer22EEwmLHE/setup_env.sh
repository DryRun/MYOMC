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

if [ -d env ]; then
	rm -rf env
fi

mkdir env
cd env
export SCRAM_ARCH=el8_amd64_gcc10
source /cvmfs/cms.cern.ch/cmsset_default.sh

scram project -n "CMSSW_12_4_16" CMSSW_12_4_16
cd CMSSW_12_4_16/src
eval `scram runtime -sh`
scram b
cd ../..

export SCRAM_ARCH=el8_amd64_gcc11
source /cvmfs/cms.cern.ch/cmsset_default.sh
scram project -n "CMSSW_13_0_13" CMSSW_13_0_13
cd CMSSW_13_0_13/src
eval `scram runtime -sh`
scram b
cd ../../

tar -czf env.tar.gz ./CMSSW*
mv env.tar.gz ..
cd ..

eval `scram unsetenv -sh`
