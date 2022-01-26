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
