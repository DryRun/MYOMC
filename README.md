# Make your own MC

This repository proves scripts to run private MC generation. It consists of the exact same cmsDriver.py commands used in central production (...painstaking copied by hand from MCM).

Setup instructions (note: `git cms-addpkg` has to work):
```
git clone git@github.com:DryRun/MYOMC.git
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
