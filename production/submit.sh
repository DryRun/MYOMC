#!/bin/bash
python3 ../crun.py VectorZPrimeGammaToQQGamma_flatmass_pt180_2017 fragment_zqq_flatmass_pt180.py RunIISummer20UL17wmLHE_pfnano \
    -e -p -f \
    --nevents_job 2000 \
    --njobs 5000 \
    --keepNANO \
    --outEOS /store/group/lpcpfnano/dryu/v2_3/2017/VectorZPrimeFlat/VectorZPrimeGammaToQQGamma_flatmass_pt180_TuneCP5_13TeV-madgraph-pythia8/VectorZPrimeFlat/20220426/0000/ \
    --seed_offset 1

python3 ../crun.py VectorZPrimeGammaToQQGamma_flatmass_pt450_2017 fragment_zqq_flatmass_pt450.py RunIISummer20UL17wmLHE_pfnano \
    -e -p -f \
    --nevents_job 2000 \
    --njobs 5000 \
    --keepNANO \
    --outEOS /store/group/lpcpfnano/dryu/v2_3/2017/VectorZPrimeFlat/VectorZPrimeGammaToQQGamma_flatmass_pt450_TuneCP5_13TeV-madgraph-pythia8/VectorZPrimeFlat/20220426/0000/ \
    --seed_offset 1

python3 ../crun.py VectorZPrimeGammaToQQGamma_flatmass_pt180_2018 fragment_zqq_flatmass_pt180.py RunIISummer20UL18wmLHE_pfnano \
    -e -p -f \
    --nevents_job 2000 \
    --njobs 5000 \
    --keepNANO \
    --outEOS /store/group/lpcpfnano/dryu/v2_3/2018/VectorZPrimeFlat/VectorZPrimeGammaToQQGamma_flatmass_pt180_TuneCP5_13TeV-madgraph-pythia8/VectorZPrimeFlat/20220426/0000/ \
    --seed_offset 1

python3 ../crun.py VectorZPrimeGammaToQQGamma_flatmass_pt450_2018 fragment_zqq_flatmass_pt450.py RunIISummer20UL18wmLHE_pfnano \
    -e -p -f \
    --nevents_job 2000 \
    --njobs 5000 \
    --keepNANO \
    --outEOS /store/group/lpcpfnano/dryu/v2_3/2018/VectorZPrimeFlat/VectorZPrimeGammaToQQGamma_flatmass_pt450_TuneCP5_13TeV-madgraph-pythia8/VectorZPrimeFlat/20220426/0000/ \
    --seed_offset 1
