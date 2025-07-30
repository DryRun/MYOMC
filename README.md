# Make your own MC

This repository proves scripts to run private MC generation. It consists of the exact same cmsDriver.py commands used in central production (...painstaking copied by hand from MCM).

Setup instructions (note: `git cms-addpkg` has to work):
```
git clone git@github.com:gabhijith/MYOMC.git
cd MYOMC
source firsttime.sh
# For future sessions, run env.sh
```

Run a test job:
```
cd $MYOMC/test
source runtest.sh local
# Or
# source runtest.sh condor
```

See the test script for the syntax. 

## NANOGEN example
NANOGEN ([twiki](https://twiki.cern.ch/twiki/bin/viewauth/CMS/NanoGen)) is a lightweight data format containing only generator-level information. The input is a pythia fragment, e.g. one downloaded from MCM or the GEN repositories. Assuming you have a fragment named `fragment.py`, the usage is as follows:
```
cd MYOMC
# source firsttime.sh # If you haven't run this before, execute this to pre-create some CMSSW environment tarballs
source env.sh
python localtest.py jobname path/to/fragment.py NANOGEN --nevents 10000

# To run on condor instead of local:
# python crun.py jobname path/to/fragment.py NANOGEN -e --nevents_job 5000 --njobs 10 --keepNANOGEN # See crun.py for more condor options like output saving, memory requirements, etc.
```
Here's an example pythia fragment, which uses a Madgraph gridpack:
<details>

  <summary>fragment.py</summary>
  
  <pre>
    
import FWCore.ParameterSet.Config as cms

externalLHEProducer = cms.EDProducer("ExternalLHEProducer",
    args = cms.vstring('/eos/.../username/gridpacks/my_gridpack_slc7_amd64_gcc900_CMSSW_12_0_2_tarball.tar.xz'),
    nEvents = cms.untracked.uint32(5000),
    numberOfParameters = cms.uint32(1),
    outputFile = cms.string('cmsgrid_final.lhe'),
    generateConcurrently = cms.untracked.bool(True),
    scriptName = cms.FileInPath('GeneratorInterface/LHEInterface/data/run_generic_tarball_cvmfs.sh')
    #scriptName = cms.FileInPath('GeneratorInterface/LHEInterface/data/run_generic_tarball_xrootd.sh')
)
import FWCore.ParameterSet.Config as cms

from Configuration.Generator.Pythia8CommonSettings_cfi import *
from Configuration.Generator.MCTunes2017.PythiaCP5Settings_cfi import *
from Configuration.Generator.PSweightsPythia.PythiaPSweightsSettings_cfi import *

generator = cms.EDFilter("Pythia8ConcurrentHadronizerFilter",
    maxEventsToPrint = cms.untracked.int32(1),
    pythiaPylistVerbosity = cms.untracked.int32(1),
    pythiaHepMCVerbosity = cms.untracked.bool(False),
    comEnergy = cms.double(13000.),
    PythiaParameters = cms.PSet(
        pythia8CommonSettingsBlock,
        pythia8CP5SettingsBlock,
        pythia8PSweightsSettingsBlock,
        parameterSets = cms.vstring('pythia8CommonSettings',
                                    'pythia8CP5Settings',
                                    'pythia8PSweightsSettings'
                                    )
    )
)
    
  </pre>

</details>
