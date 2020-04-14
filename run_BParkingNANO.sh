#!/bin/bash
MINIAODFILE=$1
NANOCONFIG=$2
NEVENTS=$3

source /cvmfs/cms.cern.ch/cmsset_default.sh

tar -xzvf CMSSW_10_2_15_skim.tar.gz
cd CMSSW_10_2_15_skim/src
eval `scram runtime -sh`
scram b -j8
cd ../..

cmsRun $CMSSW_BASE/src/PhysicsTools/BParkingNANO/test/$NANOCONFIG isMC=True inputFiles=$MINIAODFILE maxEvents=$NEVENTS
