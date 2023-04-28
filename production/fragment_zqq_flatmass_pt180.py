import FWCore.ParameterSet.Config as cms
import os
gridpack_abspath = os.path.expandvars("$_CONDOR_SCRATCH_DIR/VectorZPrimeAToQQA_flatmass_pt140_rhocut_slc7_amd64_gcc900_CMSSW_12_0_2_tarball.tar.xz")

externalLHEProducer = cms.EDProducer("ExternalLHEProducer",
    args = cms.vstring(gridpack_abspath),
    nEvents = cms.untracked.uint32(5000),
    numberOfParameters = cms.uint32(1),
    outputFile = cms.string('cmsgrid_final.lhe'),
    generateConcurrently = cms.untracked.bool(True),
    scriptName = cms.FileInPath('GeneratorInterface/LHEInterface/data/run_generic_tarball_cvmfs.sh')
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
                                    'pythia8PSweightsSettings',
                                    )
    )
)

genParticlesForFilter = cms.EDProducer(
    "GenParticleProducer",
    saveBarCodes=cms.untracked.bool(True),
    src=cms.InputTag("generator", "unsmeared"),
    abortOnUnknownPDGCode=cms.untracked.bool(False)
)

genfilter = cms.EDFilter(
    "GenParticleSelector",
    src = cms.InputTag("genParticlesForFilter"),
    cut = cms.string(' && '.join([
        '(pdgId==55)',#Added photon pt cut
        'pt>180.',
        'isLastCopy()',
    ]))
)

gencount = cms.EDFilter(
    "CandViewCountFilter",
    src = cms.InputTag("genfilter"),
    minNumber = cms.uint32(1)
)

ProductionFilterSequence = cms.Sequence(
    generator * (genParticlesForFilter + genfilter + gencount)
)


# Link to generator fragment:
# genFragments/Hadronizer/13TeV/Hadronizer_TuneCP5_13TeV_generic_LHE_pythia8_cff.py
