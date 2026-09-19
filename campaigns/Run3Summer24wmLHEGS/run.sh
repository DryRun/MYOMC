# Run private production using Run3Summer24 settings.
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
RSEED=$((JOBINDEX * MAX_NTHREADS * 4 + 1001 + $RANDOM)) # Space out seeds; Madgraph concurrent mode adds idx(thread) to random seed. The extra *4 is a paranoia factor.

if [ -z "$6" ]; then
    PILEUP_FILELIST="dbs:/Neutrino_E-10_gun/Run3Summer21PrePremix-Summer23_130X_mcRun3_2023_realistic_v13-v1/PREMIX" 
else
    PILEUP_FILELIST="filelist:$6"
fi

echo "Fragment=$FRAGMENT"
echo "Job name=$NAME"
echo "NEvents=$NEVENTS"
echo "Random seed=$RSEED"
echo "Pileup filelist=$PILEUP_FILELIST"

TOPDIR=$PWD

export SCRAM_ARCH=el8_amd64_gcc12

source /cvmfs/cms.cern.ch/cmsset_default.sh
if [ -r CMSSW_14_0_18/src ] ; then
  echo release CMSSW_14_0_18 already exists
else
  scram p CMSSW CMSSW_14_0_18
fi
cd CMSSW_14_0_18/src
eval `scram runtime -sh`

mv ../../Configuration .
scram b
cd ../..

# wmLHE
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
    --era Run3_2024 \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    --beamspot DBrealistic \
    --step LHE,GEN,SIM \
    --geometry DB:Extended \
    --conditions 140X_mcRun3_2024_realistic_v26 \
    --customise_commands process.RandomNumberGeneratorService.externalLHEProducer.initialSeed=${RSEED}\\nprocess.source.numberEventsInLuminosityBlock="cms.untracked.uint32(1000)" \
    --datatier GEN-SIM,LHE \
    --eventcontent RAWSIM,LHE \
    --python_filename Run3Summer24wmLHE_${NAME}_cfg.py \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \
    --fileout file:Run3Summer24wmLHEGS_$NAME_$JOBINDEX.root \
    --number $NEVENTS \
    --number_out $NEVENTS \
    --no_exec \
    --mc
cmsRun "Run3Summer24wmLHE_${NAME}_cfg.py"
if [ ! -f "Run3Summer24wmLHEGS_$NAME_$JOBINDEX.root" ]; then
    echo "Run3Summer24wmLHEGS_$NAME_$JOBINDEX.root not found. Exiting."
    return 1
fi

# DIGIPremix
cd $TOPDIR
cmsDriver.py  \
    --era Run3_2024 \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    --procModifiers premix_stage2 \
    --datamix PreMix \
    --step DIGI,DATAMIX,L1,DIGI2RAW,HLT:2024v14 \
    --geometry DB:Extended \
    --conditions 140X_mcRun3_2024_realistic_v26 \
    --datatier GEN-SIM-RAW \
    --eventcontent PREMIXRAW \
    --python_filename "Run3Summer24DRPremix0_${NAME}_cfg.py" \
    --filein "file:Run3Summer24wmLHEGS_$NAME_$JOBINDEX.root" \
    --fileout "file:Run3Summer24DRPremix0_$NAME_$JOBINDEX.root" \
    --number $NEVENTS \
    --number_out $NEVENTS \
    --pileup_input "$PILEUP_FILELIST" \
    --no_exec \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \
    --mc 
cmsRun "Run3Summer24DRPremix0_${NAME}_cfg.py"
if [ ! -f "Run3Summer24DRPremix0_$NAME_$JOBINDEX.root" ]; then
    echo "Run3Summer24DRPremix0_$NAME_$JOBINDEX.root not found. Exiting."
    return 1
fi

#RECO
cd $TOPDIR
cmsDriver.py  \
    --era Run3_2024 \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    --step RAW2DIGI,L1Reco,RECO,RECOSIM \
    --geometry DB:Extended \
    --conditions 140X_mcRun3_2024_realistic_v26 \
    --datatier AODSIM \
    --eventcontent AODSIM \
    --python_filename "Run3Summer24DRPremix_${NAME}_cfg.py" \
    --filein "file:Run3Summer24DRPremix0_$NAME_$JOBINDEX.root" \
    --fileout "file:Run3Summer24RECO_$NAME_$JOBINDEX.root" \
    --number $NEVENTS  \
    --number_out $NEVENTS  \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \
    --no_exec \
    --mc
cmsRun "Run3Summer24DRPremix_${NAME}_cfg.py"
if [ ! -f "Run3Summer24RECO_$NAME_$JOBINDEX.root" ]; then
    echo "Run3Summer24RECO_$NAME_$JOBINDEX.root not found. Exiting."
    return 1
fi

export SCRAM_ARCH=el8_amd64_gcc12

source /cvmfs/cms.cern.ch/cmsset_default.sh
if [ -r CMSSW_15_0_2/src ] ; then
  echo release CMSSW_15_0_2 already exists
else
  scram p CMSSW CMSSW_15_0_2
fi
cd CMSSW_15_0_2/src
eval `scram runtime -sh`

mv ../../Configuration .
scram b
cd ../..

cd $TOPDIR
# MINIAODv6
cmsDriver.py  \
    --era Run3_2024 \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    --step PAT \
    --geometry DB:Extended \
    --conditions 150X_mcRun3_2024_realistic_v2 \
    --datatier MINIAODSIM \
    --eventcontent MINIAODSIM1 \
    --python_filename "Run3Summer24MiniAOD_${NAME}_cfg.py" \
    --filein "file:Run3Summer24RECO_$NAME_$JOBINDEX.root" \
    --fileout "file:Run3Summer24MiniAOD_$NAME_$JOBINDEX.root" \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \
    --number $NEVENTS \
    --number_out $NEVENTS \
    --no_exec \
    --mc

cmsRun "Run3Summer24MiniAOD_${NAME}_cfg.py"
if [ ! -f "Run3Summer24MiniAOD_$NAME_$JOBINDEX.root" ]; then
    echo "Run3Summer24MiniAOD_$NAME_$JOBINDEX.root not found. Exiting."
    return 1
fi

#NanoAODv15
cd $TOPDIR
cmsDriver.py  \
    --scenario pp \
    --era Run3_2024 \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    --step NANO \
    --conditions 150X_mcRun3_2024_realistic_v2 \
    --datatier NANOAODSIM \
    --eventcontent NANOAODSIM1 \
    --python_filename "Run3Summer24NanoAODv15_${NAME}_cfg.py" \
    --filein "file:Run3Summer24MiniAOD_$NAME_$JOBINDEX.root" \
    --fileout "file:Run3Summer24NanoAODv15_$NAME_$JOBINDEX.root" \
    --number $NEVENTS \
    --number_out $NEVENTS \
    --no_exec \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \ \
    --mc 
cmsRun "Run3Summer24NanoAODv15_${NAME}_cfg.py"
if [ ! -f "Run3Summer24NanoAODv15_$NAME_$JOBINDEX.root" ]; then
    echo "Run3Summer24NanoAODv15_$NAME_$JOBINDEX.root not found. Exiting."
    return 1
fi
