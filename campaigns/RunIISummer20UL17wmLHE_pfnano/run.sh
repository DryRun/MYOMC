# Run private production using RunIIFall18GS settings.
# Local example:
# source run.sh MyMCName /path/to/fragment.py 1000 1 1 filelist:/path/to/pileup/list.txt
# 
# Batch example:
# python crun.py MyMCName /path/to/fragment.py --outEOS /store/user/myname/somefolder --keepMini --nevents_job 10000 --njobs 100 --env
# See crun.py for full options, especially regarding transfer of outputs.
# Make sure your gridpack is somewhere readable, e.g. EOS or CVMFS.
# Make sure to run setup_env.sh first to create a CMSSW tarball (have to patch the DR step to avoid taking forever to uniqify the list of 300K pileup files)
echo $@

if [ -z "$1" ]; then
    echo "Argument 1 (name of job) is mandatory."
    return 1
fi
NAME=$1

if [ -z $2 ]; then
    echo "Argument 2 (fragment path) is mandatory."
    return 1
fi
FRAGMENT=$2
echo "Input arg 2 = $FRAGMENT"
FRAGMENT=$(readlink -e $FRAGMENT)
echo "After readlink fragment = $FRAGMENT"

if [ -z "$3" ]; then
    NEVENTS=100
else
    NEVENTS=$3
fi

if [ -z "$4" ]; then
    JOBINDEX=1
else
    JOBINDEX=$4
fi

if [ -z "$5" ]; then
    MAX_NTHREADS=8
else
    MAX_NTHREADS=$5
fi
RSEED=$((JOBINDEX * MAX_NTHREADS * 4 + 1001)) # Space out seeds; Madgraph concurrent mode adds idx(thread) to random seed

if [ -z "$6" ]; then
    PILEUP_FILELIST="dbs:/Neutrino_E-10_gun/RunIISummer20ULPrePremix-UL17_106X_mc2017_realistic_v6-v3/PREMIX"
else
    PILEUP_FILELIST="filelist:$6"
fi

echo "Fragment=$FRAGMENT"
echo "Job name=$NAME"
echo "NEvents=$NEVENTS"
echo "Random seed=$RSEED"
echo "Pileup filelist=$PILEUP_FILELIST"

TOPDIR=$PWD

# wmLHE
export SCRAM_ARCH=slc7_amd64_gcc700
source /cvmfs/cms.cern.ch/cmsset_default.sh
if [ -r CMSSW_10_6_40/src ] ; then 
    echo release CMSSW_10_6_40 already exists
    cd CMSSW_10_6_40/src
    eval `scram runtime -sh`
else
    scram project -n "CMSSW_10_6_40" CMSSW_10_6_40
    cd CMSSW_10_6_40/src
    eval `scram runtime -sh`
fi

mkdir -pv $CMSSW_BASE/src/Configuration/GenProduction/python
cp $FRAGMENT $CMSSW_BASE/src/Configuration/GenProduction/python/fragment.py
if [ ! -f "$CMSSW_BASE/src/Configuration/GenProduction/python/fragment.py" ]; then
    echo "Fragment copy failed"
    exit 1
fi
cd $CMSSW_BASE/src
scram b
cd $TOPDIR

#cat $CMSSW_BASE/src/Configuration/GenProduction/python/fragment.py

cmsDriver.py Configuration/GenProduction/python/fragment.py \
    --python_filename "RunIISummer20UL17wmLHE_${NAME}_cfg.py" \
    --eventcontent RAWSIM,LHE \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    --datatier GEN,LHE \
    --fileout "file:RunIISummer20UL17wmLHE_$NAME_$JOBINDEX.root" \
    --conditions 106X_mc2017_realistic_v6 \
    --beamspot Realistic25ns13TeVEarly2017Collision \
    --step LHE,GEN \
    --geometry DB:Extended \
    --era Run2_2017 \
    --no_exec \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \
    --customise_commands "process.source.numberEventsInLuminosityBlock=cms.untracked.uint32(1000)\\nprocess.RandomNumberGeneratorService.externalLHEProducer.initialSeed=${RSEED}" \
    --mc \
    -n $NEVENTS 

cmsRun "RunIISummer20UL17wmLHE_${NAME}_cfg.py"
if [ ! -f "RunIISummer20UL17wmLHE_$NAME_$JOBINDEX.root" ]; then
    echo "RunIISummer20UL17wmLHE_$NAME_$JOBINDEX.root not found. Exiting."
    return 1
fi


# SIM
export SCRAM_ARCH=slc7_amd64_gcc700
source /cvmfs/cms.cern.ch/cmsset_default.sh
if [ -r CMSSW_10_6_17_patch1/src ] ; then
    echo release CMSSW_10_6_17_patch1 already exists
    cd CMSSW_10_6_17_patch1/src
    eval `scram runtime -sh`
else
    scram project -n "CMSSW_10_6_17_patch1" CMSSW_10_6_17_patch1
    cd CMSSW_10_6_17_patch1/src
    eval `scram runtime -sh`
fi
cd $CMSSW_BASE/src
scram b
cd $TOPDIR

cmsDriver.py  \
    --python_filename "RunIISummer20UL17SIM_${NAME}_cfg.py" \
    --eventcontent RAWSIM \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    --datatier GEN-SIM \
    --fileout "file:RunIISummer20UL17SIM_$NAME_$JOBINDEX.root" \
    --conditions 106X_mc2017_realistic_v6 \
    --beamspot Realistic25ns13TeVEarly2017Collision \
    --step SIM \
    --geometry DB:Extended \
    --filein "file:RunIISummer20UL17wmLHE_$NAME_$JOBINDEX.root" \
    --era Run2_2017 \
    --runUnscheduled \
    --no_exec \
    --mc \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \
    -n $NEVENTS

cmsRun "RunIISummer20UL17SIM_${NAME}_cfg.py"
if [ ! -f "RunIISummer20UL17SIM_$NAME_$JOBINDEX.root" ]; then
    echo "RunIISummer20UL17SIM_$NAME_$JOBINDEX.root not found. Exiting."
    return 1
fi


# DIGIPremix
cd $TOPDIR
cmsDriver.py  \
    --python_filename "RunIISummer20UL17DIGIPremix_${NAME}_cfg.py" \
    --eventcontent PREMIXRAW \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    --datatier GEN-SIM-DIGI \
    --filein "file:RunIISummer20UL17SIM_$NAME_$JOBINDEX.root" \
    --fileout "file:RunIISummer20UL17DIGIPremix_$NAME_$JOBINDEX.root" \
    --pileup_input "$PILEUP_FILELIST" \
    --conditions 106X_mc2017_realistic_v6 \
    --step DIGI,DATAMIX,L1,DIGI2RAW \
    --procModifiers premix_stage2 \
    --geometry DB:Extended \
    --datamix PreMix \
    --era Run2_2017 \
    --runUnscheduled \
    --no_exec \
    --mc \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \
    -n $NEVENTS
cmsRun "RunIISummer20UL17DIGIPremix_${NAME}_cfg.py"
if [ ! -f "RunIISummer20UL17DIGIPremix_$NAME_$JOBINDEX.root" ]; then
    echo "RunIISummer20UL17DIGIPremix_$NAME_$JOBINDEX.root not found. Exiting."
    return 1
fi


# HLT
export SCRAM_ARCH=slc7_amd64_gcc630
source /cvmfs/cms.cern.ch/cmsset_default.sh
if [ -r CMSSW_9_4_14_UL_patch1/src ] ; then
    echo release CMSSW_9_4_14_UL_patch1 already exists
    cd CMSSW_9_4_14_UL_patch1/src
    eval `scram runtime -sh`
else
    scram project -n "CMSSW_9_4_14_UL_patch1" CMSSW_9_4_14_UL_patch1
    cd CMSSW_9_4_14_UL_patch1/src
    eval `scram runtime -sh`
fi
cd $CMSSW_BASE/src
scram b
cd $TOPDIR

cmsDriver.py  \
    --python_filename "RunIISummer20UL17HLT_${NAME}_cfg.py" \
    --eventcontent RAWSIM \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    --datatier GEN-SIM-RAW \
    --filein "file:RunIISummer20UL17DIGIPremix_$NAME_$JOBINDEX.root" \
    --fileout "file:RunIISummer20UL17HLT_$NAME_$JOBINDEX.root" \
    --conditions 94X_mc2017_realistic_v15 \
    --customise_commands 'process.source.bypassVersionCheck = cms.untracked.bool(True)' \
    --step HLT:2e34v40 \
    --geometry DB:Extended \
    --era Run2_2017 \
    --no_exec \
    --mc \
    -n $NEVENTS
cmsRun "RunIISummer20UL17HLT_${NAME}_cfg.py"
if [ ! -f "RunIISummer20UL17HLT_$NAME_$JOBINDEX.root" ]; then
    echo "RunIISummer20UL17HLT_$NAME_$JOBINDEX.root not found. Exiting."
    return 1
fi


# RECO
export SCRAM_ARCH=slc7_amd64_gcc700
cd CMSSW_10_6_17_patch1/src
eval `scram runtime -sh`
cd $CMSSW_BASE/src
scram b
cd $TOPDIR

cmsDriver.py  \
    --python_filename "RunIISummer20UL17RECO_${NAME}_cfg.py" \
    --eventcontent AODSIM \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    --datatier AODSIM \
    --filein "file:RunIISummer20UL17HLT_$NAME_$JOBINDEX.root" \
    --fileout "file:RunIISummer20UL17RECO_$NAME_$JOBINDEX.root" \
    --conditions 106X_mc2017_realistic_v6 \
    --step RAW2DIGI,L1Reco,RECO,RECOSIM \
    --geometry DB:Extended \
    --era Run2_2017 \
    --runUnscheduled \
    --no_exec \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \
    --mc \
    -n $NEVENTS 
cmsRun "RunIISummer20UL17RECO_${NAME}_cfg.py"
if [ ! -f "RunIISummer20UL17RECO_$NAME_$JOBINDEX.root" ]; then
    echo "RunIISummer20UL17RECO_$NAME_$JOBINDEX.root not found. Exiting."
    return 1
fi


# MiniAOD
export SCRAM_ARCH=slc7_amd64_gcc700
source /cvmfs/cms.cern.ch/cmsset_default.sh
if [ -r CMSSW_10_6_20/src ] ; then
    echo release CMSSW_10_6_20 already exists
    cd CMSSW_10_6_20/src
    eval `scram runtime -sh`
else
    scram project -n "CMSSW_10_6_20" CMSSW_10_6_20
    cd CMSSW_10_6_20/src
    eval `scram runtime -sh`
fi
cd $CMSSW_BASE/src
scram b
cd $TOPDIR

cmsDriver.py  \
    --python_filename "RunIISummer20UL17MINIAODSIM_${NAME}_cfg.py" \
    --eventcontent MINIAODSIM \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    --datatier MINIAODSIM \
    --filein "file:RunIISummer20UL17RECO_$NAME_$JOBINDEX.root" \
    --fileout "file:RunIISummer20UL17MINIAODSIM_$NAME_$JOBINDEX.root" \
    --conditions 106X_mc2017_realistic_v9 \
    --step PAT \
    --procModifiers run2_miniAOD_UL \
    --geometry DB:Extended \
    --era Run2_2017 \
    --runUnscheduled \
    --no_exec \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \
    --mc \
    -n $NEVENTS
cmsRun "RunIISummer20UL17MINIAODSIM_${NAME}_cfg.py"
if [ ! -f "RunIISummer20UL17MINIAODSIM_$NAME_$JOBINDEX.root" ]; then
    echo "RunIISummer20UL17MINIAODSIM_$NAME_$JOBINDEX.root not found. Exiting."
    return 1
fi


# PFNano
export SCRAM_ARCH=slc7_amd64_gcc700
source /cvmfs/cms.cern.ch/cmsset_default.sh
if [ -r CMSSW_10_6_26_PFNano/src ] ; then
    echo release CMSSW_10_6_26_PFNano already exists
    cd CMSSW_10_6_26_PFNano/src
    eval `scram runtime -sh`
else
    scram project -n "CMSSW_10_6_26_PFNano" CMSSW_10_6_26
    cd CMSSW_10_6_26_PFNano/src
    eval `scram runtime -sh`
    git cms-init
    git cms-rebase-topic DryRun:CMSSW_10_6_19_patch_pfnano
    git clone git@github.com:DAZSLE/PFNano PhysicsTools/PFNano
    cd PhysicsTools/PFNano
    git checkout tags/v2.3 -b v2.3
    cd $CMSSW_BASE/src
    scram b
fi
cd $CMSSW_BASE/src
scram b
cd $TOPDIR

cmsDriver.py \
    --python_filename "RunIISummer20UL17PFNANOAODSIM_${NAME}_cfg.py" \
    --mc \
    --eventcontent NANOAODSIM \
    --datatier NANOAODSIM \
    --step NANO \
    --conditions 106X_mc2017_realistic_v9 \
    --era Run2_2017,run2_nanoAOD_106Xv2 \
    --customise_commands="process.add_(cms.Service('InitRootHandlers', EnableIMT = cms.untracked.bool(False)))" \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \ \
    --filein "file:RunIISummer20UL17MINIAODSIM_$NAME_$JOBINDEX.root" \
    --fileout "file:RunIISummer20UL17PFNANOAODSIM_$NAME_$JOBINDEX.root" \
    --customise PhysicsTools/PFNano/ak15/addAK15_cff.setupPFNanoAK15_mc \
    -n $NEVENTS \
    --no_exec
cmsRun "RunIISummer20UL17PFNANOAODSIM_${NAME}_cfg.py"
if [ ! -f "RunIISummer20UL17PFNANOAODSIM_$NAME_$JOBINDEX.root" ]; then
    echo "RunIISummer20UL17PFNANOAODSIM_$NAME_$JOBINDEX.root not found. Exiting."
    return 1
fi
