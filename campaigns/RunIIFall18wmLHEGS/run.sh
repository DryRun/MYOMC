# Run private production using RunIIFall18GS settings.
# Local example:
# source run.sh MyMCName /path/to/fragment.py 1000 1 filelist:/path/to/pileup/list.txt
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
RSEED=$((JOBINDEX + 1001))


if [ -z "$5" ]; then
    MAX_NTHREADS=8
else
    MAX_NTHREADS=$5
fi

if [ -z "$6" ]; then
	PILEUP_FILELIST="dbs:/Neutrino_E-10_gun/RunIISummer17PrePremix-PUAutumn18_102X_upgrade2018_realistic_v15-v1/GEN-SIM-DIGI-RAW"
else
	PILEUP_FILELIST=$6
fi

echo "Fragment=$FRAGMENT"
echo "Job name=$NAME"
echo "NEvents=$NEVENTS"
echo "Random seed=$RSEED"
echo "Pileup filelist=$PILEUP_FILELIST"

TOPDIR=$PWD

# wmLHEGS
export SCRAM_ARCH=slc6_amd64_gcc700 #slc7_amd64_gcc700
source /cvmfs/cms.cern.ch/cmsset_default.sh
if [ -r CMSSW_10_2_21_wmLHEGS/src ] ; then 
    echo release CMSSW_10_2_21_wmLHEGS already exists
	cd CMSSW_10_2_21_wmLHEGS/src
	eval `scram runtime -sh`
else
    scram project -n "CMSSW_10_2_21_wmLHEGS" CMSSW_10_2_21
	cd CMSSW_10_2_21_wmLHEGS/src
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
	--fileout "file:RunIIFall18wmLHEGS_$NAME_$JOBINDEX.root" \
	--mc \
	--eventcontent RAWSIM,LHE \
	--datatier GEN-SIM,LHE \
	--conditions 102X_upgrade2018_realistic_v11 \
	--beamspot Realistic25ns13TeVEarly2018Collision \
	--step LHE,GEN,SIM \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \
	--geometry DB:Extended \
	--era Run2_2018 \
	--python_filename "RunIIFall18wmLHEGS_${NAME}_cfg.py" \
	--no_exec \
	--customise Configuration/DataProcessing/Utils.addMonitoring \
	--customise_commands "process.source.numberEventsInLuminosityBlock=\"cms.untracked.uint32(1000)\"\\nprocess.RandomNumberGeneratorService.externalLHEProducer.initialSeed=${RSEED}" \
	-n $NEVENTS

cmsRun "RunIIFall18wmLHEGS_${NAME}_cfg.py"
if [ ! -f "RunIIFall18wmLHEGS_$NAME_$JOBINDEX.root" ]; then
	echo "RunIIFall18wmLHEGS_$NAME_$JOBINDEX.root not found. Exiting."
	return 1
fi

# DR
#export HOME=/home/dryu
export SCRAM_ARCH=slc6_amd64_gcc700
echo "DEBUG : Starting DR"
echo $PWD
ls -lrth .
if [ -r CMSSW_10_2_5_DRMiniAOD ] ; then 
    echo release CMSSW_10_2_5_DRMiniAOD already exists
    cd CMSSW_10_2_5_DRMiniAOD/src
    eval `scram runtime -sh`
elif [ -z $MYOMC ] && [ -r $MYOMC/RunIIFall18wmLHEGS/env/CMSSW_10_2_5_DRMiniAOD ]; then 
    echo "Using precompiled release at $MYOMC/CMSSW_10_2_5_DRMiniAOD"
    cd $MYOMC/CMSSW_10_2_5_DRMiniAOD/src
    eval `scram runtime -sh`    
else
    echo "Checking out new DR release and patching"
    scram project -n "CMSSW_10_2_5_DRMiniAOD" CMSSW_10_2_5
    cd CMSSW_10_2_5_DRMiniAOD/src
    eval `scram runtime -sh`
    # Hack configBuilder to be less dumb
    git cms-addpkg Configuration/Applications
	git cherry-pick 6c56c41899274246b2c9ba777f12ba9c1155acd6^..ca45cfac90f87030695fea8b328f08bb5c4c6998
    #sed -i "s/if not entry in prim:/if True:/g" Configuration/Applications/python/ConfigBuilder.py
    sed -i "s/print(\"found/print(\"redacted\")#print(\"found files/g" Configuration/Applications/python/ConfigBuilder.py
    sed -i "s/print \"found/print \"redacted\"#print \"found files/g" Configuration/Applications/python/ConfigBuilder.py
fi
#cat Configuration/Applications/python/ConfigBuilder.py
scram b -j8
cd $TOPDIR

cmsDriver.py step1 \
	--filein "file:RunIIFall18wmLHEGS_$NAME_$JOBINDEX.root" \
	--fileout "file:RunIIFall18DRstep1_$NAME_$JOBINDEX.root" \
	--mc \
	--pileup_input "$PILEUP_FILELIST" \
	--eventcontent PREMIXRAW \
	--datatier GEN-SIM-RAW \
	--conditions 102X_upgrade2018_realistic_v15 \
	--step DIGI,DATAMIX,L1,DIGI2RAW,HLT:@relval2018 \
	--procModifiers premix_stage2 \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \
	--geometry DB:Extended \
	--datamix PreMix \
	--era Run2_2018 \
	--python_filename "RunIIFall18DRstep1_${NAME}_cfg.py" \
	--no_exec \
	--customise Configuration/DataProcessing/Utils.addMonitoring \
	-n $NEVENTS
#	--pileup_input "dbs:/Neutrino_E-10_gun/RunIISummer17PrePremix-PUAutumn18_102X_upgrade2018_realistic_v15-v1/GEN-SIM-DIGI-RAW" \	
cmsRun "RunIIFall18DRstep1_${NAME}_cfg.py"
if [ ! -f "RunIIFall18DRstep1_$NAME_$JOBINDEX.root" ]; then
	echo "RunIIFall18DRstep1_$NAME_$JOBINDEX.root not found. Exiting."
	return 1
fi


cmsDriver.py step2 \
	--filein "file:RunIIFall18DRstep1_$NAME_$JOBINDEX.root" \
	--fileout "file:RunIIFall18DRstep2_$NAME_$JOBINDEX.root" \
	--mc \
	--eventcontent AODSIM \
	--runUnscheduled \
	--datatier AODSIM \
	--conditions 102X_upgrade2018_realistic_v15 \
	--step RAW2DIGI,L1Reco,RECO,RECOSIM,EI \
	--procModifiers premix_stage2 \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \
	--era Run2_2018 \
	--python_filename "RunIIFall18DRstep2_${NAME}_cfg.py" \
	--no_exec \
	--customise Configuration/DataProcessing/Utils.addMonitoring \
	-n $NEVENTS
cmsRun "RunIIFall18DRstep2_${NAME}_cfg.py"
if [ ! -f "RunIIFall18DRstep2_$NAME_$JOBINDEX.root" ]; then
	echo "RunIIFall18DRstep2_$NAME_$JOBINDEX.root not found. Exiting."
	return 1
fi


# MiniAOD
# Uses same CMSSW as DR
# I know this is supposed to be Autumn18, but whatever
cmsDriver.py step1 \
	--filein "file:RunIIFall18DRstep2_$NAME_$JOBINDEX.root" \
	--fileout "file:RunIIFall18MiniAOD_$NAME_$JOBINDEX.root" \
	--mc \
	--eventcontent MINIAODSIM \
	--runUnscheduled \
	--datatier MINIAODSIM \
	--conditions 102X_upgrade2018_realistic_v15 \
	--step PAT \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \
	--geometry DB:Extended \
	--era Run2_2018 \
	--python_filename "RunIIFall18MiniAOD_${NAME}_cfg.py" \
	--no_exec \
	--customise Configuration/DataProcessing/Utils.addMonitoring \
	-n $NEVENTS
cmsRun "RunIIFall18MiniAOD_${NAME}_cfg.py"
if [ ! -f "RunIIFall18MiniAOD_$NAME_$JOBINDEX.root" ]; then
	echo "RunIIFall18MiniAOD_$NAME_$JOBINDEX.root not found. Exiting."
	return 1
fi


# NanoAOD
#export SCRAM_ARCH=slc6_amd64_gcc700
#source /cvmfs/cms.cern.ch/cmsset_default.sh
#if [ -r CMSSW_10_2_18_NanoAOD/src ] ; then 
# echo release CMSSW_10_2_18_NanoAOD already exists
#else
#scram project -n "CMSSW_10_2_18_NanoAOD" CMSSW_10_2_18
#fi
#cd CMSSW_10_2_18_NanoAOD/src
#eval `scram runtime -sh`
#scram b
#cd $TOPDIR
#
#cmsDriver.py step1 \
#	--filein "file:RunIIFall18MiniAOD_$NAME_$JOBINDEX.root" \
#	--fileout "file:RunIIFall18NanoAOD_$NAME_$JOBINDEX.root" \
#	--mc \
#	--eventcontent NANOAODSIM \
#	--datatier NANOAODSIM \
#	--conditions 102X_upgrade2018_realistic_v20 \
#	--step NANO \
#   --nThreads $(( $MAX_NTHREADS < 2 ? $MAX_NTHREADS : 2 )) \
#	--era Run2_2018,run2_nanoAOD_102Xv1 \
#	--python_filename "RunIIFall18NanoAOD_${NAME}_cfg.py" \
#	--no_exec \
#	--customise Configuration/DataProcessing/Utils.addMonitoring \
#	-n $NEVENTS
#cmsRun "RunIIFall18NanoAOD_${NAME}_cfg.py"
