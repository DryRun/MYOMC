from PhysicsTools.NanoAOD.taus_cff import *
from PhysicsTools.NanoAOD.jets_cff import *
from PhysicsTools.NanoAOD.globals_cff import *
from PhysicsTools.NanoAOD.genparticles_cff import *
from PhysicsTools.NanoAOD.particlelevel_cff import *
from PhysicsTools.NanoAOD.lheInfoTable_cfi import *
from PhysicsTools.NanoAOD.genWeightsTable_cfi import *

nanoMetadata = cms.EDProducer("UniqueStringProducer",
    strings = cms.PSet(
        tag = cms.string("untagged"),
    )
)

metGenTable = cms.EDProducer("SimpleCandidateFlatTableProducer",
    src = cms.InputTag("genMetTrue"),
    name = cms.string("GenMET"),
    doc = cms.string("Gen MET"),
    singleton = cms.bool(True),
    extension = cms.bool(False),
    variables = cms.PSet(
       pt  = Var("pt",  float, doc="pt", precision=10),
       phi = Var("phi", float, doc="phi", precision=10),
    ),
)

nanogenSequence = cms.Sequence(
    nanoMetadata+
    particleLevel+
    genJetTable+
    patJetPartons+
    genJetFlavourAssociation+
    genJetFlavourTable+
    genJetAK8Table+
    genJetAK8FlavourAssociation+
    genJetAK8FlavourTable+
    tauGenJets+
    tauGenJetsSelectorAllHadrons+
    genVisTaus+
    genVisTauTable+
    genTable+
    genParticleTables+
    tautagger+
    rivetProducerHTXS+
    particleLevelTables+
    metGenTable+
    genWeightsTable+
    lheInfoTable
)

nanogenMiniSequence = cms.Sequence(
    nanoMetadata+
    mergedGenParticles+
    genParticles2HepMC+
    particleLevel+
    genJetTable+
    patJetPartons+
    genJetFlavourAssociation+
    genJetFlavourTable+
    genJetAK8Table+
    genJetAK8FlavourAssociation+
    genJetAK8FlavourTable+
    tauGenJets+
    tauGenJetsSelectorAllHadrons+
    genVisTaus+
    genVisTauTable+
    genTable+
    genParticleTables+
    tautagger+
    genParticles2HepMCHiggsVtx+
    rivetProducerHTXS+
    particleLevelTables+
    metGenTable+
    genWeightsTable+
    lheInfoTable
)

NANOAODGENoutput = cms.OutputModule("NanoAODOutputModule",
    compressionAlgorithm = cms.untracked.string('LZMA'),
    compressionLevel = cms.untracked.int32(9),
    dataset = cms.untracked.PSet(
        dataTier = cms.untracked.string('NANOAODSIM'),
        filterName = cms.untracked.string('')
    ),
    fileName = cms.untracked.string('nanogen.root'),
    outputCommands = cms.untracked.vstring(
        'drop *',
        "keep nanoaodFlatTable_*Table_*_*",     # event data
        "keep String_*_genModel_*",  # generator model data
        "keep nanoaodMergeableCounterTable_*Table_*_*", # accumulated per/run or per/lumi data
        "keep nanoaodUniqueString_nanoMetadata_*_*",   # basic metadata
    )
)

def customizeNanoGENFromMini(process):
    process.lheInfoTable.storeLHEParticles = True
    process.lheInfoTable.precision = 14
    process.genParticleTable.src = "prunedGenParticles"
    process.patJetPartons.particles = "prunedGenParticles"
    process.particleLevel.src = "genParticles2HepMC:unsmeared"
    process.rivetProducerHTXS.HepMCCollection = "genParticles2HepMCHiggsVtx:unsmeared"

    process.genJetTable.src = "slimmedGenJets"
    process.genJetFlavourAssociation.jets = process.genJetTable.src
    process.genJetFlavourTable.src = process.genJetTable.src
    process.genJetFlavourTable.jetFlavourInfos = "genJetFlavourAssociation"
    process.genJetAK8Table.src = "slimmedGenJetsAK8"
    process.genJetAK8FlavourAssociation.jets = process.genJetAK8Table.src
    process.genJetAK8FlavourTable.src = process.genJetAK8Table.src
    process.tauGenJets.GenParticles = "prunedGenParticles"
    process.genVisTaus.srcGenParticles = "prunedGenParticles"

    return process

def customizeNanoGEN(process):
    process.lheInfoTable.storeLHEParticles = True
    process.lheInfoTable.precision = 14
    process.genParticleTable.src = "genParticles"
    process.patJetPartons.particles = "genParticles"
    process.particleLevel.src = "generatorSmeared"
    process.rivetProducerHTXS.HepMCCollection = "generatorSmeared"

    process.genJetTable.src = "ak4GenJets"
    process.genJetFlavourAssociation.jets = process.genJetTable.src
    process.genJetFlavourTable.src = process.genJetTable.src
    process.genJetFlavourTable.jetFlavourInfos = "genJetFlavourAssociation"
    process.genJetAK8Table.src = "ak8GenJets"
    process.genJetAK8FlavourAssociation.jets = process.genJetAK8Table.src
    process.genJetAK8FlavourTable.src = process.genJetAK8Table.src
    process.tauGenJets.GenParticles = "genParticles"
    process.genVisTaus.srcGenParticles = "genParticles"

    return process
