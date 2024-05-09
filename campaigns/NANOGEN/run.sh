# Run NANOGEN
# Local example:
# source run.sh MyMCName /path/to/fragment.py 1000
# 
# Batch example:
# python crun.py MyMCName /path/to/fragment.py --outEOS /store/user/myname/somefolder --keepMini --nevents_job 10000 --njobs 100 --env
# See crun.py for full options, especially regarding transfer of outputs.
# Make sure your gridpack is somewhere readable, e.g. EOS or CVMFS.
# Make sure to run setup_env.sh first to create a CMSSW tarball (have to patch the DR step to avoid taking forever to uniqify the list of 300K pileup files)
echo $@

if [ -z "$1" ]; then
    echo "Argument 1 (name of job) is mandatory."
    exit 1
fi
NAME=$1

if [ -z $2 ]; then
    echo "Argument 2 (fragment path) is mandatory."
    exit 1
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

RSEED=$((JOBINDEX * MAX_NTHREADS * 100 + 1001)) # Space out seeds; Madgraph concurrent mode adds idx(thread) to random seed


echo "Fragment=$FRAGMENT"
echo "Job name=$NAME"
echo "NEvents=$NEVENTS"
echo "Random seed=$RSEED"

TOPDIR=$PWD

# NANOGEN
# Setup CMSSW and merge NANOGEN stuff
#export SCRAM_ARCH=slc6_amd64_gcc700
export SCRAM_ARCH=slc7_amd64_gcc820
if [ -r CMSSW_10_6_22_NANOGEN ] ; then
    echo release CMSSW_10_6_22_NANOGEN already exists
    cd CMSSW_10_6_22_NANOGEN/src
    eval `scram runtime -sh`
    scram b -j8
    cd $TOPDIR
else
    scram project -n "CMSSW_10_6_22_NANOGEN" CMSSW_10_6_22
    cd CMSSW_10_6_22_NANOGEN/src
    eval `scram runtime -sh`
    #git cms-init
    #git cms-merge-topic DryRun:CMSSW_10_6_22-NANOGEN
    scram b -j8
    cd $TOPDIR
fi

# Setup fragment
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

# cmsDriver and run
cmsDriver.py Configuration/GenProduction/python/fragment.py \
    --python_filename "NANOGEN_${NAME}_cfg.py" \
    --eventcontent NANOAODGEN \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    --datatier NANOGEN \
    --fileout "file:NANOGEN_$NAME_$JOBINDEX.root" \
    --conditions 106X_mc2017_realistic_v6 \
    --beamspot Realistic25ns13TeVEarly2017Collision \
    --step LHE,GEN,NANOGEN \
    --geometry DB:Extended \
    --era Run2_2017,run2_nanoAOD_106Xv2 \
    --no_exec \
    --mc \
    --nThreads $MAX_NTHREADS \
    --customise_commands "process.source.numberEventsInLuminosityBlock=cms.untracked.uint32(1000)\\n\
process.RandomNumberGeneratorService.externalLHEProducer.initialSeed=${RSEED}\\n\
process.genParticleTable.variables.mass.precision=cms.untracked.int32(-1)\\n\
process.genJetTable.variables.mass.precision=cms.untracked.int32(-1)\\n" \
    -n $NEVENTS

cmsRun "NANOGEN_${NAME}_cfg.py"
if [ ! -f "NANOGEN_$NAME_$JOBINDEX.root" ]; then
    echo "NANOGEN_$NAME_$JOBINDEX.root not found. Exiting."
    return 1
fi
