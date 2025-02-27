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
RSEED=$((JOBINDEX * MAX_NTHREADS * 4 + 1001)) # Space out seeds; Madgraph concurrent mode adds idx(thread) to random seed. The extra *4 is a paranoia factor.

if [ -z "$6" ]; then
    PILEUP_FILELIST="dbs:/Neutrino_E-10_gun/Run3Summer21PrePremix-Summer23BPix_130X_mcRun3_2023_realistic_postBPix_v1-v1/PREMIX" 
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
export SCRAM_ARCH=el8_amd64_gcc11
source /cvmfs/cms.cern.ch/cmsset_default.sh
if [ -r CMSSW_13_0_14/src ] ; then 
    echo release CMSSW_13_0_14 already exists
    cd CMSSW_13_0_14/src
    eval `scram runtime -sh`
else
    scram project -n "CMSSW_13_0_14" CMSSW_13_0_14
    cd CMSSW_13_0_14/src
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
    --python_filename "Run3Summer22wmLHE_${NAME}_cfg.py" \
    --eventcontent RAWSIM,LHE \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    --datatier GEN-SIM,LHE \
    --fileout "file:Run3Summer22wmLHEGS_$NAME_$JOBINDEX.root" \
    --conditions 130X_mcRun3_2023_realistic_postBPix_v2 \
    --beamspot Realistic25ns13p6TeVEarly2023Collision \
    --step LHE,GEN,SIM \
    --geometry DB:Extended \
    --era Run3_2023 \
    --no_exec \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \
    --customise_commands "process.source.numberEventsInLuminosityBlock=cms.untracked.uint32(1000)\\nprocess.RandomNumberGeneratorService.externalLHEProducer.initialSeed=${RSEED}" \
    --mc \
    -n $NEVENTS 
cmsRun "Run3Summer22wmLHE_${NAME}_cfg.py"
if [ ! -f "Run3Summer22wmLHEGS_$NAME_$JOBINDEX.root" ]; then
    echo "Run3Summer22wmLHEGS_$NAME_$JOBINDEX.root not found. Exiting."
    return 1
fi


# DIGIPremix
cd $TOPDIR
cmsDriver.py  \
    --python_filename "Run3Summer22DRPremix0_${NAME}_cfg.py" \
    --eventcontent PREMIXRAW \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    --datatier GEN-SIM-RAW \
    --filein "file:Run3Summer22wmLHEGS_$NAME_$JOBINDEX.root" \
    --fileout "file:Run3Summer22DRPremix0_$NAME_$JOBINDEX.root" \
    --pileup_input "$PILEUP_FILELIST" \
    --conditions 130X_mcRun3_2023_realistic_postBPix_v2 \
    --step DIGI,DATAMIX,L1,DIGI2RAW,HLT:2023v12 \
    --procModifiers premix_stage2 \
    --geometry DB:Extended \
    --datamix PreMix \
    --era Run3_2023 \
    --no_exec \
    --mc \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \
    -n $NEVENTS
cmsRun "Run3Summer22DRPremix0_${NAME}_cfg.py"
if [ ! -f "Run3Summer22DRPremix0_$NAME_$JOBINDEX.root" ]; then
    echo "Run3Summer22DRPremix0_$NAME_$JOBINDEX.root not found. Exiting."
    return 1
fi


# RECO
cmsDriver.py  \
    --python_filename "Run3Summer22DRPremix_${NAME}_cfg.py" \
    --eventcontent AODSIM \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    --datatier AODSIM \
    --filein "file:Run3Summer22DRPremix0_$NAME_$JOBINDEX.root" \
    --fileout "file:Run3Summer22RECO_$NAME_$JOBINDEX.root" \
    --conditions 130X_mcRun3_2023_realistic_postBPix_v2 \
    --step RAW2DIGI,L1Reco,RECO,RECOSIM \
    --geometry DB:Extended \
    --era Run3_2023 \
    --no_exec \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \
    --mc \
    -n $NEVENTS 
cmsRun "Run3Summer22DRPremix_${NAME}_cfg.py"
if [ ! -f "Run3Summer22RECO_$NAME_$JOBINDEX.root" ]; then
    echo "Run3Summer22RECO_$NAME_$JOBINDEX.root not found. Exiting."
    return 1
fi


cmsDriver.py  \
    --python_filename "Run3Summer22MINIAODSIM_${NAME}_cfg.py" \
    --eventcontent MINIAODSIM \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    --datatier MINIAODSIM \
    --filein "file:Run3Summer22RECO_$NAME_$JOBINDEX.root" \
    --fileout "file:Run3Summer22MiniAODv4_$NAME_$JOBINDEX.root" \
    --conditions 130X_mcRun3_2022_realistic_v5 \
    --step PAT \
    --geometry DB:Extended \
    --era Run3_2023 \
    --no_exec \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \
    --mc \
    -n $NEVENTS
cmsRun "Run3Summer22MINIAODSIM_${NAME}_cfg.py"
if [ ! -f "Run3Summer22MiniAODv4_$NAME_$JOBINDEX.root" ]; then
    echo "Run3Summer22MiniAODv4_$NAME_$JOBINDEX.root not found. Exiting."
    return 1
fi

#NanoAODv12
cmsDriver.py  \
    --python_filename "Run3Summer22NanoAODv12_${NAME}_cfg.py" \
    --filein "file:Run3Summer22MiniAODv4_$NAME_$JOBINDEX.root" \
    --fileout "file:Run3Summer22NanoAODv12_$NAME_$JOBINDEX.root" \
    --eventcontent NANOEDMAODSIM \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    --datatier NANOAODSIM \
    --conditions 130X_mcRun3_2022_realistic_v5 \
    --step NANO \
    --scenario pp \
    --era Run3_2023 \
    --no_exec \
    --mc \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \ \
    -n $NEVENTS
cmsRun "Run3Summer22NanoAODv12_${NAME}_cfg.py"
if [ ! -f "Run3Summer22NanoAODv12_$NAME_$JOBINDEX.root" ]; then
    echo "Run3Summer22NanoAODv12_$NAME_$JOBINDEX.root not found. Exiting."
    return 1
fi
