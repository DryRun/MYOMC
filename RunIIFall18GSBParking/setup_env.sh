#!/bin/bash
export SYSTEM_RELEASE=`cat /etc/redhat-release`
if { [[ $SYSTEM_RELEASE == *"release 7"* ]] }; then
  echo "Running this script in SLC6."
  if { [[ $(hostname -s) = lxplus* ]]}; then
  	ssh lxplus6 -c "cd $PWD; source setup_env.sh;"
  elif { [[ $(hostname -s) = cmslpc* ]] }; then
  	ssh cmslpc-sl6 -c "cd $PWD; source setup_env.sh;"
  else
  	echo "Not on cmslpc or lxplus, not sure what to do."
  	return 1
  fi
fi

mkdir env
cd env
export SCRAM_ARCH=slc6_amd64_gcc700
source /cvmfs/cms.cern.ch/cmsset_default.sh
scram project -n "CMSSW_10_2_22_GS" CMSSW_10_2_22
cd CMSSW_10_2_22_GS/src
eval `scram runtime -sh`
scram b
cd ../..

scram project -n "CMSSW_10_2_13_DR" CMSSW_10_2_13
cd CMSSW_10_2_13_DR/src
eval `scram runtime -sh`
# Hack configBuilder to be less dumb
# Hack configBuilder to be less dumb
git cms-addpkg Configuration/Applications
git cms-merge-topic kpedro88:filesFromList_102X
sed -i "s/if not entry in prim:/if True:/g" Configuration/Applications/python/ConfigBuilder.py
sed -i "s/print(\"found/print(\"redacted\")#print(\"found files/g" Configuration/Applications/python/ConfigBuilder.py
sed -i "s/print \"found/print \"redacted\"#print \"found files/g" Configuration/Applications/python/ConfigBuilder.py
scram b -j8
cd ../../

scram project -n "CMSSW_10_2_14_RECOBParkingMiniAOD" CMSSW_10_2_14
cd CMSSW_10_2_14_RECOBParkingMiniAOD/src
eval `scram runtime -sh`
scram b
cd ../../

scram project -n "CMSSW_10_2_18_NanoAOD" CMSSW_10_2_18
cd CMSSW_10_2_18_NanoAOD/src
eval `scram runtime -sh`
scram b
cd ../../

tar -czvf env.tar.gz ./CMSSW*
mv env.tar.gz ..
cd ..
