#!/bin/bash
mkdir env
cd env
export SCRAM_ARCH=slc7_amd64_gcc700
source /cvmfs/cms.cern.ch/cmsset_default.sh
scram project -n "CMSSW_10_2_3_GS" CMSSW_10_2_3
cd CMSSW_10_2_3_GS/src
eval `scram runtime -sh`
scram b
cd ../..

scram project -n "CMSSW_10_2_5_DRMiniAOD" CMSSW_10_2_5
cd CMSSW_10_2_5_DRMiniAOD/src
eval `scram runtime -sh`
# Hack configBuilder to be less dumb
git cms-addpkg Configuration/Applications
sed -i "s/if not entry in prim:/if True:/g" Configuration/Applications/python/ConfigBuilder.py
sed -i "s/print(\"found/print(\"redacted\")#print(\"found files/g" Configuration/Applications/python/ConfigBuilder.py
sed -i "s/print \"found/print \"redacted\"#print \"found files/g" Configuration/Applications/python/ConfigBuilder.py
#cat Configuration/Applications/python/ConfigBuilder.py
scram b -j8
cd ../../

scram project -n "CMSSW_10_2_18_NanoAOD" CMSSW_10_2_18
cd CMSSW_10_2_18_NanoAOD/src
eval `scram runtime -sh`
scram b
cd ../../

tar -czvf env.tar.gz ./CMSSW*

