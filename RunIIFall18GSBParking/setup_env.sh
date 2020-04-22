#!/bin/bash
export SYSTEM_RELEASE=`cat /etc/redhat-release`
if { [[ $SYSTEM_RELEASE == *"release 7"* ]]; }; then
  echo "Running setup_env.sh on SLC6."
  if { [[ $(hostname -s) = lxplus* ]]; }; then
  	ssh -Y lxplus6 "cd $PWD; source setup_env.sh;"
  elif { [[ $(hostname -s) = cmslpc* ]]; }; then
  	ssh -Y cmslpc-sl6 "cd $PWD; source setup_env.sh;"
  else
  	echo "Not on cmslpc or lxplus, not sure what to do."
  	return 1
  fi
  return 1
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
git cherry-pick 6c56c41899274246b2c9ba777f12ba9c1155acd6^..ca45cfac90f87030695fea8b328f08bb5c4c6998
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
