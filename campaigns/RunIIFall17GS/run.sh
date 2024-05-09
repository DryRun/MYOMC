#Run private production using RunIIFall17GS settings.
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
    PILEUP_FILELIST="dbs:/Neutrino_E-10_gun/RunIISummer17PrePremix-MCv2_correctPU_94X_mc2017_realistic_v9-v1/GEN-SIM-DIGI-RAW"
else
    PILEUP_FILELIST=$6
fi

echo "Fragment=$FRAGMENT"
echo "Job name=$NAME"
echo "NEvents=$NEVENTS"
echo "Random seed=$RSEED"
echo "Pileup filelist=$PILEUP_FILELIST"


# GENSIM
export SCRAM_ARCH=slc7_amd64_gcc700
source /cvmfs/cms.cern.ch/cmsset_default.sh
if [ -r CMSSW_9_3_17_GS/src ] ; then 
 echo release CMSSW_9_3_17_GS already exists
else
scram project -n "CMSSW_9_3_17_GS" CMSSW_9_3_17
fi
cd CMSSW_9_3_17_GS/src
eval `scram runtime -sh`

mkdir -pv $CMSSW_BASE/src/Configuration/GenProduction/python
cp $FRAGMENT $CMSSW_BASE/src/Configuration/GenProduction/python/fragment.py
if [ ! -f "$CMSSW_BASE/src/Configuration/GenProduction/python/fragment.py" ]; then
	echo "Fragment copy failed"
	exit 1
fi
cd $CMSSW_BASE/src
scram b
cd ../..

#cat $CMSSW_BASE/src/Configuration/GenProduction/python/fragment.py

cmsDriver.py Configuration/GenProduction/python/EXO-RunIIFall17GS-05020-fragment.py \
    --fileout "file:RunIIFall17GENSIM_$NAME_$JOBINDEX.root" \
    --mc \
    --eventcontent RAWSIM \
    --datatier GEN-SIM \
    --conditions 93X_mc2017_realistic_v3 \
    --beamspot Realistic25ns13TeVEarly2017Collision \
    --step GEN,SIM \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \
    --geometry DB:Extended \
    --era Run2_2017 \
	--python_filename "RunIIFall17GS_${NAME}_cfg.py" \
    --no_exec \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
    --customise_commands process.source.numberEventsInLuminosityBlock="cms.untracked.uint32(1000)\\nprocess.RandomNumberGeneratorService.generator.initialSeed=${RSEED}" \
	-n $NEVENTS
cmsRun "RunIIFall17GS_${NAME}_cfg.py"

# DR
if [ -r CMSSW_9_4_7_DR/src ] ; then 
    echo release CMSSW_9_4_7_DR already exists
else
    scram project -n "CMSSW_9_4_7_DR" CMSSW_9_4_7
fi
cd CMSSW_9_4_7_DR/src
eval `scram runtime -sh`
# Hack configBuilder to be less dumb
#git cms-addpkg Configuration/Applications
#sed -i "s/if not entry in prim:/if True:/g" Configuration/Applications/python/ConfigBuilder.py
#sed -i "s/print(\"found/print(\"redacted\")#print(\"found files/g" Configuration/Applications/python/ConfigBuilder.py
#sed -i "s/print \"found/print \"redacted\"#print \"found files/g" Configuration/Applications/python/ConfigBuilder.py
#cat Configuration/Applications/python/ConfigBuilder.py
scram b -j8
cd ../../

cmsDriver.py step1 \
	--filein "file:RunIIFall17GENSIM_$NAME_$JOBINDEX.root" \
	--fileout "file:RunIIFall17DRstep1_$NAME_$JOBINDEX.root" \
	--pileup_input "$PILEUP_FILELIST" \
    --mc \
    --eventcontent PREMIXRAW \
    --datatier GEN-SIM-RAW \
    --conditions 94X_mc2017_realistic_v11 \
    --step DIGIPREMIX_S2,DATAMIX,L1,DIGI2RAW,HLT:2e34v40 \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \
    --datamix PreMix \
    --era Run2_2017 \
	--python_filename "RunIIFall17DRstep1_${NAME}_cfg.py" \
    --no_exec \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
	-n $NEVENTS
#    --pileup_input "dbs:/Neutrino_E-10_gun/RunIISummer17PrePremix-MCv2_correctPU_94X_mc2017_realistic_v9-v1/GEN-SIM-DIGI-RAW" \
cmsRun "RunIIFall17DRstep1_${NAME}_cfg.py"

cmsDriver.py step2 \
	--filein "file:RunIIFall17DRstep1_$NAME_$JOBINDEX.root" \
	--fileout "file:RunIIFall17DRstep2_$NAME_$JOBINDEX.root" \
    --mc \
    --eventcontent AODSIM \
    --runUnscheduled \
    --datatier AODSIM \
    --conditions 94X_mc2017_realistic_v11 \
    --step RAW2DIGI,RECO,RECOSIM,EI \
    --nThreads $(( $MAX_NTHREADS < 8 ? $MAX_NTHREADS : 8 )) \
    --era Run2_2017 \
	--python_filename "RunIIFall17DRstep2_${NAME}_cfg.py" \
    --no_exec \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
	-n $NEVENTS
cmsRun "RunIIFall17DRstep2_${NAME}_cfg.py"


# MiniAOD
# Uses same CMSSW as DR
cmsDriver.py step1 \
	--filein "file:RunIIFall17DRstep2_$NAME_$JOBINDEX.root" \
	--fileout "file:RunIIFall17MiniAOD_$NAME_$JOBINDEX.root" \
    --mc \
    --eventcontent MINIAODSIM \
    --runUnscheduled \
    --datatier MINIAODSIM \
    --conditions 94X_mc2017_realistic_v14 \
    --step PAT \
    --nThreads $(( $MAX_NTHREADS < 4 ? $MAX_NTHREADS : 4 )) \
    --scenario pp \
    --era Run2_2017,run2_miniAOD_94XFall17 \
	--python_filename "RunIIFall17MiniAOD_${NAME}_cfg.py" \
    --no_exec \
    --customise Configuration/DataProcessing/Utils.addMonitoring
	-n $NEVENTS
cmsRun "RunIIFall17MiniAOD_${NAME}_cfg.py"


# NanoAOD
export SCRAM_ARCH=slc7_amd64_gcc700
source /cvmfs/cms.cern.ch/cmsset_default.sh
if [ -r CMSSW_10_2_18_NanoAOD/src ] ; then 
 echo release CMSSW_10_2_18_NanoAOD already exists
else
scram project -n "CMSSW_10_2_18_NanoAOD" CMSSW_10_2_18
fi
cd CMSSW_10_2_18_NanoAOD/src
eval `scram runtime -sh`
scram b
cd ../../

cmsDriver.py step1 \
	--filein "file:RunIIFall17MiniAOD_$NAME_$JOBINDEX.root" \
	--fileout "file:RunIIFall17NanoAOD_$NAME_$JOBINDEX.root" \
    --mc \
    --eventcontent NANOAODSIM \
    --datatier NANOAODSIM \
    --conditions 102X_mc2017_realistic_v7 \
    --step NANO \
    --nThreads $(( $MAX_NTHREADS < 2 ? $MAX_NTHREADS : 2 )) \
    --era Run2_2017,run2_nanoAOD_94XMiniAODv2 \
	--python_filename "RunIIFall17NanoAOD_${NAME}_cfg.py" \
    --no_exec \
    --customise Configuration/DataProcessing/Utils.addMonitoring \
	-n $NEVENTS
cmsRun "RunIIFall17NanoAOD_${NAME}_cfg.py"
