from CRABClient.UserUtilities import config, ClientException, getUsernameFromCRIC
from PhysicsTools.BParkingNano.skim_version import skim_version
#from input_crab_data import dataset_files
import yaml
import datetime
from fnmatch import fnmatch
from argparse import ArgumentParser

production_tag = datetime.date.today().strftime('%Y%b%d')

if __name__ == '__main__':

    from CRABAPI.RawCommand import crabCommand
    from CRABClient.ClientExceptions import ClientException
    from httplib import HTTPException
    from multiprocessing import Process

    def submit(config):
        try:
            crabCommand('submit', config=config)
        except HTTPException as hte:
            print "Failed submitting task: %s" % (hte.headers)
            print hte
        except ClientException as cle:
            print "Failed submitting task: %s" % (cle)


    import argparse
    parser = argparse.ArgumentParser(description="Run gridpack to NANO on condor")
    parser.add_argument("name", type=str, help="Name of output folder (will be created in current directory)")
    parser.add_argument("fragment", type=str, help="Path to fragment")
    parser.add_argument("campaign", type=str, help="Name of campaign")
    #parser.add_argument("--env", "-e", action="store_true", help="Use pre-packaged CMSSW environments (run setup_env.sh first)")
    parser.add_argument("--pileup_file", "-p", type=str, help="Use premade pileup input file instead of DAS query (saves some time)")
    parser.add_argument("--nevents_job", type=int, default=100, help="Number of events per job")
    parser.add_argument("--njobs", type=int, default=1, help="Number jobs")
    parser.add_argument("--keepNANOGEN", action="store_true", help="Keep NANOGEN")
    parser.add_argument("--keepNANO", action='store_true', help="Keep NanoAOD")
    parser.add_argument("--keepMINI", action='store_true', help="Keep MiniAOD")
    parser.add_argument("--keepDR", action='store_true', help="Keep DR")
    parser.add_argument("--keepRECO", action='store_true', help="Keep RECO")
    parser.add_argument("--keepGS", action='store_true', help="Keep GS")
    parser.add_argument("--outEOS", type=str, help="Transfer files to EOS instead of back to AFS")
    parser.add_argument("--outcp", type=str, help="Transfer output files with cp")
    parser.add_argument("--gfalcp", type=str, help="Transfer output files with gfalcp")
    parser.add_argument("--os", type=str, help="Force SLC6 or CC7 (might not work!)")
    parser.add_argument("--seed_offset", type=int, default=0, help="Offset random seed (useful for extending previous runs)")
    parser.add_argument("--mem", type=int, default=7900, help="Memory to request")
    parser.add_argument("--max_nthreads", type=int, default=8, help="Maximum number of threads (reduce if condor priority is a problem)")
    args = parser.parse_args()

    with open(args.yaml) as f:
        doc = yaml.load(f) # Parse YAML file
        common = doc['common'] if 'common' in doc else {'data' : {}, 'mc' : {}}
        
        # loop over samples
        for sample, info in doc['samples'].iteritems():
            print("\n\n*** Sample {} ***".format(sample))
            # Given we have repeated datasets check for different parts
            parts = info['parts'] if 'parts' in info else [None]
            for part in parts:
                name = sample % part if part is not None else sample
                
                # filter names according to what we need
                if not fnmatch(name, args.filter): continue
                print 'submitting', name

                isMC = info['isMC']

                this_config = config()
                this_config.section_('General')
                this_config.General.transferOutputs = True
                this_config.General.transferLogs = True
                this_config.General.workArea = 'BParkingNANO_%s' % production_tag

                this_config.section_('Data')
                this_config.Data.publication = False
                #this_config.Data.outLFNDirBase = '/store/group/cmst3/group/bpark/%s' % (this_config.General.workArea)
                this_config.Data.outLFNDirBase = '/store/user/{}/BParkingNANO/{}/'.format(getUsernameFromCRIC(), skim_version)

                this_config.Data.inputDBS = 'global'

                this_config.section_('JobType')
                this_config.JobType.pluginName = 'Analysis'
                this_config.JobType.psetName = '../test/run_nano_FFR_AllJpsiMuMu_cfg.py'
                this_config.JobType.maxJobRuntimeMin = 2750
                this_config.JobType.allowUndistributedCMSSW = True

                this_config.section_('User')
                this_config.section_('Site')
                this_config.Site.storageSite = 'T3_US_Brown'

                this_config.Data.inputDataset = info['dataset'] % part \
                                                                     if part is not None else \
                                                                            info['dataset']

                this_config.General.requestName = name
                common_branch = 'mc' if isMC else 'data'
                this_config.Data.splitting = 'FileBased' if isMC else 'LumiBased'
                #this_config.Data.splitting = 'FileBased' if isMC else 'Automatic'
                if not isMC:
                        this_config.Data.lumiMask = info.get(
                                'lumimask', 
                                common[common_branch].get('lumimask', None)
                        )
                        if "%d" in this_config.Data.lumiMask and part is not None:
                            this_config.Data.lumiMask = this_config.Data.lumiMask % part
                else:
                        this_config.Data.lumiMask = ''

                this_config.Data.unitsPerJob = info.get(
                        'splitting',
                        common[common_branch].get('splitting', None)
                )

                if "totalUnits" in info:
                    this_config.Data.totalUnits = info.get("totalUnits")

                globaltag = info.get(
                        'globaltag',
                        common[common_branch].get('globaltag', None)
                )
                
                this_config.JobType.pyCfgParams = [
                        'isMC=%s' % isMC, 'reportEvery=1000',
                        'tag=%s' % production_tag,
                        'globalTag=%s' % globaltag,
                ]
                
                this_config.JobType.outputFiles = ['_'.join(['BParkNANO', 'mc' if isMC else 'data', production_tag])+'.root']
                
                print this_config
                p = Process(target=submit, args=(this_config,))
                p.start()
                p.join()
                #submit(this_config)
            print("*** Done with Sample {} ***\n\n".format(sample))

