#!/bin/bash
echo "X509_USER_PROXY:"
echo "${X509_USER_PROXY}"
ls -lrth $X509_USER_PROXY

echo "Proxy info:"
voms-proxy-info --all

echo "Trying to run xrdcp"
xrdls root://cmsxrootd-site.fnal.gov//store/mc/RunIISummer20ULPrePremix/Neutrino_E-10_gun/PREMIX/UL18_106X_upgrade2018_realistic_v11_L1v1-v2/230012/30F05C7E-9D03-364E-84A7-91A980F1837A.root .
ls -lrth

#mkdir hide
#mv *root hide

echo "Done."