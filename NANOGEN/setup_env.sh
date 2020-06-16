#!/bin/bash
export SYSTEM_RELEASE=`cat /etc/redhat-release`
if { [[ $SYSTEM_RELEASE == *"release 7"* ]]; }; then
  echo "Running setup_env.sh on SLC6."
  if { [[ $(hostname -s) = lxplus* ]]; }; then
  	ssh -Y lxplus6 "cd $PWD; source setup_env.sh;"
  elif { [[ $(hostname -s) = cmslpc* ]]; }; then
    #ssh -Y cmslpc-sl6 "cd $PWD; source setup_env.sh;"
    ssh -Y cmslpc23 "cd $PWD; source setup_env.sh;"
  else
  	echo "Not on cmslpc or lxplus, not sure what to do."
  	return 1
  fi
  return 1
fi

mkdir env
cd env
export SCRAM_ARCH=slc6_amd64_gcc700
scram project -n "CMSSW_10_2_22_NANOGEN" CMSSW_10_2_22
cd CMSSW_10_2_22_NANOGEN/src
eval `scram runtime -sh`
git cms-init
git cms-merge-topic DryRun:CMSSW_10_2_22-NANOGEN
scram b -j8
cd ../../

tar -czvf env.tar.gz ./CMSSW*
mv env.tar.gz ..
cd ..

