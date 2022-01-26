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
RSEED=$((JOBINDEX + 1001))


if [ -z "$5" ]; then
    MAX_NTHREADS=8
else
    MAX_NTHREADS=$5
fi

if [ -z "$6" ]; then
    PILEUP_FILELIST="dbs:/Neutrino_E-10_gun/RunIISummer20ULPrePremix-UL16_106X_mcRun2_asymptotic_v13-v1/PREMIX" 
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
if [ -r CMSSW_10_6_28_patch1/src ] ; then 
    echo release CMSSW_10_6_28_patch1 already exists
    cd CMSSW_10_6_28_patch1/src
    eval `scram runtime -sh`
else
    scram project -n "CMSSW_10_6_28_patch1" CMSSW_10_6_28_patch1
    cd CMSSW_10_6_28_patch1/src
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
    --python_filename "RunIISummer20UL16wmLHEGENAPV_${NAME}_cfg.py" \
    --eventcontent RAWSIM,LHE \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    --datatier GEN,LHE \
    --fileout "file:RunIISummer20UL16wmLHEGENAPV_$NAME_$JOBINDEX.root" \
    --conditions 106X_mcRun2_asymptotic_preVFP_v8 \
    --beamspot Realistic25ns13TeV2016Collision \
    --step LHE,GEN \
    --geometry DB:Extended \
    --era Run2_2016_HIPM \
    --no_exec \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \
    --customise_commands "process.source.numberEventsInLuminosityBlock=cms.untracked.uint32(1000)\\nprocess.RandomNumberGeneratorService.externalLHEProducer.initialSeed=${RSEED}" \
    --mc \
    -n $NEVENTS 
cmsRun "RunIISummer20UL16wmLHEGENAPV_${NAME}_cfg.py"
if [ ! -f "RunIISummer20UL16wmLHEGENAPV_$NAME_$JOBINDEX.root" ]; then
    echo "RunIISummer20UL16wmLHEGENAPV_$NAME_$JOBINDEX.root not found. Exiting."
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
    --python_filename "RunIISummer20UL16SIMAPV_${NAME}_cfg.py" \
	--eventcontent RAWSIM \
	--customise Configuration/DataProcessing/Utils.addMonitoring \
	--datatier GEN-SIM \
    --fileout "file:RunIISummer20UL16SIMAPV_$NAME_$JOBINDEX.root" \
	--conditions 106X_mcRun2_asymptotic_preVFP_v8 \
	--beamspot Realistic25ns13TeV2016Collision \
	--step SIM \
	--geometry DB:Extended \
    --filein "file:RunIISummer20UL16wmLHEGENAPV_$NAME_$JOBINDEX.root" \
	--era Run2_2016_HIPM \
	--runUnscheduled \
	--no_exec \
	--mc \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \
    -n $NEVENTS
cmsRun "RunIISummer20UL16SIMAPV_${NAME}_cfg.py"
if [ ! -f "RunIISummer20UL16SIMAPV_$NAME_$JOBINDEX.root" ]; then
    echo "RunIISummer20UL16SIMAPV_$NAME_$JOBINDEX.root not found. Exiting."
    return 1
fi


# DIGIPremix
cd $TOPDIR
cmsDriver.py  \
    --python_filename "RunIISummer20UL16DIGIPremixAPV_${NAME}_cfg.py" \
	--eventcontent PREMIXRAW \
	--customise Configuration/DataProcessing/Utils.addMonitoring \
	--datatier GEN-SIM-DIGI \
    --filein "file:RunIISummer20UL16SIMAPV_$NAME_$JOBINDEX.root" \
    --fileout "file:RunIISummer20UL16DIGIPremixAPV_$NAME_$JOBINDEX.root" \
    --pileup_input "$PILEUP_FILELIST" \
	--conditions 106X_mcRun2_asymptotic_preVFP_v8 \
	--step DIGI,DATAMIX,L1,DIGI2RAW \
	--procModifiers premix_stage2 \
	--geometry DB:Extended \
	--datamix PreMix \
	--era Run2_2016_HIPM \
	--runUnscheduled \
	--no_exec \
	--mc \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \
    -n $NEVENTS
cmsRun "RunIISummer20UL16DIGIPremixAPV_${NAME}_cfg.py"
if [ ! -f "RunIISummer20UL16DIGIPremixAPV_$NAME_$JOBINDEX.root" ]; then
    echo "RunIISummer20UL16DIGIPremixAPV_$NAME_$JOBINDEX.root not found. Exiting."
    return 1
fi


# HLT
export SCRAM_ARCH=slc7_amd64_gcc630
source /cvmfs/cms.cern.ch/cmsset_default.sh
if [ -r CMSSW_8_0_33_UL/src ] ; then
    echo release CMSSW_8_0_33_UL already exists
    cd CMSSW_8_0_33_UL/src
    eval `scram runtime -sh`
else
    scram project -n "CMSSW_8_0_33_UL" CMSSW_8_0_33_UL
    cd CMSSW_8_0_33_UL/src
    eval `scram runtime -sh`
fi
cd $CMSSW_BASE/src
scram b
cd $TOPDIR

cmsDriver.py  \
    --python_filename "RunIISummer20UL16HLTAPV_${NAME}_cfg.py" \
    --eventcontent RAWSIM \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    --outputCommand "keep *_mix_*_*,keep *_genPUProtons_*_*" \
    --inputCommands "keep *","drop *_*_BMTF_*","drop *PixelFEDChannel*_*_*_*" \
    --datatier GEN-SIM-RAW \
    --filein "file:RunIISummer20UL16DIGIPremixAPV_$NAME_$JOBINDEX.root" \
    --fileout "file:RunIISummer20UL16HLTAPV_$NAME_$JOBINDEX.root" \
    --conditions 80X_mcRun2_asymptotic_2016_TrancheIV_v6 \
    --customise_commands 'process.source.bypassVersionCheck = cms.untracked.bool(True)' \
    --step HLT:25ns15e33_v4 \
    --geometry DB:Extended \
    --era Run2_2016 \
    --no_exec \
    --mc \
    -n $NEVENTS

cmsRun "RunIISummer20UL16HLTAPV_${NAME}_cfg.py"
if [ ! -f "RunIISummer20UL16HLTAPV_$NAME_$JOBINDEX.root" ]; then
    echo "RunIISummer20UL16HLTAPV_$NAME_$JOBINDEX.root not found. Exiting."
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
    --python_filename "RunIISummer20UL16RECOAPV_${NAME}_cfg.py" \
	--eventcontent AODSIM \
	--customise Configuration/DataProcessing/Utils.addMonitoring \
	--datatier AODSIM \
    --filein "file:RunIISummer20UL16HLTAPV_$NAME_$JOBINDEX.root" \
    --fileout "file:RunIISummer20UL16RECOAPV_$NAME_$JOBINDEX.root" \
	--conditions 106X_mcRun2_asymptotic_preVFP_v8 \
	--step RAW2DIGI,L1Reco,RECO,RECOSIM \
	--geometry DB:Extended \
	--era Run2_2016_HIPM \
	--runUnscheduled \
	--no_exec \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \
	--mc \
    -n $NEVENTS 
cmsRun "RunIISummer20UL16RECOAPV_${NAME}_cfg.py"
if [ ! -f "RunIISummer20UL16RECOAPV_$NAME_$JOBINDEX.root" ]; then
    echo "RunIISummer20UL16RECOAPV_$NAME_$JOBINDEX.root not found. Exiting."
    return 1
fi


# MiniAOD
export SCRAM_ARCH=slc7_amd64_gcc700
source /cvmfs/cms.cern.ch/cmsset_default.sh
if [ -r CMSSW_10_6_25/src ] ; then
    echo release CMSSW_10_6_25 already exists
    cd CMSSW_10_6_25/src
    eval `scram runtime -sh`
else
    scram project -n "CMSSW_10_6_25" CMSSW_10_6_25
    cd CMSSW_10_6_25/src
    eval `scram runtime -sh`
fi
cd $CMSSW_BASE/src
scram b
cd $TOPDIR

cmsDriver.py  \
    --python_filename "RunIISummer20UL16MINIAODSIMAPV_${NAME}_cfg.py" \
	--eventcontent MINIAODSIM \
	--customise Configuration/DataProcessing/Utils.addMonitoring \
	--datatier MINIAODSIM \
    --filein "file:RunIISummer20UL16RECOAPV_$NAME_$JOBINDEX.root" \
    --fileout "file:RunIISummer20UL16MINIAODSIMAPV_$NAME_$JOBINDEX.root" \
	--conditions 106X_mcRun2_asymptotic_preVFP_v11 \
	--step PAT \
	--procModifiers run2_miniAOD_UL \
	--geometry DB:Extended \
	--era Run2_2016_HIPM \
	--runUnscheduled \
	--no_exec \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \
	--mc \
    -n $NEVENTS
cmsRun "RunIISummer20UL16MINIAODSIMAPV_${NAME}_cfg.py"
if [ ! -f "RunIISummer20UL16MINIAODSIMAPV_$NAME_$JOBINDEX.root" ]; then
    echo "RunIISummer20UL16MINIAODSIMAPV_$NAME_$JOBINDEX.root not found. Exiting."
    return 1
fi
