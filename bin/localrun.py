#!/usr/bin/env python
# Run gridpack to NANO on condor

import os
import sys

MYOMCPATH = os.getenv("MYOMCPATH")
if not MYOMCPATH:
    raise ValueError("Environment variable MYOMCPATH must be set. Call env.sh.")

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Run gridpack to NANO on condor")
    parser.add_argument("name", type=str, help="Name of output folder (will be created in current directory)")
    parser.add_argument("fragment", type=str, help="Path to fragment")
    parser.add_argument("campaign", type=str, help="Name of campaign")
    parser.add_argument("--nevents", type=int, default=100, help="Number of events per job")
    parser.add_argument("--seed_offset", type=int, default=0, help="Offset random seed (useful for extending previous runs)")
    args = parser.parse_args()

    # Campaign check
    known_campaigns = [x for x in os.listdir(f"{os.path.expandvars("$MYOMCPATH")}/campaigns/") if x[:3]=="Run"]
    known_campaigns.append("NANOGEN")
    if not args.campaign in known_campaigns:
        raise ValueError("Unknown campaign: {}".format(args.campaign))

    # Check fragment exists
    fragment_abspath = os.path.abspath(args.fragment)
    if not os.path.isfile(fragment_abspath):
        raise ValueError("Couldn't find fragment at {}".format(fragment_abspath))
    print "Using fragment at {}".format(fragment_abspath)

    # Check proxy, make new one if necessary
    proxy_path = os.path.expandvars("$HOME/private/x509up")
    if not os.path.isfile(proxy_path):
        make_proxy(proxy_path)
    elif get_proxy_lifetime(proxy_path) < 24: # Require proxy with >24h left
        make_proxy(proxy_path)
    else:
        print("Using existing x509 proxy:")
        os.system("voms-proxy-info")

    # Check OS
    if args.os:
        if not args.os in ["SLCern6", "CentOS7"]:
            raise ValueError("--os must be SLCern6 or CentOS7.")

    # Create and move to working directory
    if os.path.isdir(args.name):
        raise ValueError("Output directory {} already exists!".format(args.name))
    os.system("mkdir -pv {}".format(args.name))
    cwd = os.getcwd()
    os.chdir(args.name)

    # Submit to condor
    with open("runwrapper.sh", 'w') as run_script:
        run_script.write("#!/bin/bash\n")
        run_script.write("ls -lrth\n")
        run_script.write("pwd\n")
        run_script.write("mkdir work\n")
        run_script.write("cd work\n")
        run_script.write("source /cvmfs/cms.cern.ch/cmsset_default.sh\n")
        if args.env:
            run_script.write("mv ../env.tar.gz .\n")
            run_script.write("tar -xzf env.tar.gz\n")
            run_script.write("echo \"After untarring env:\"\n")
            run_script.write("ls -lrth\n")
            run_script.write("for cdir in ./CMSSW*; do\n")
            run_script.write("    echo $cdir\n")
            run_script.write("    cd $cdir/src\n")
            run_script.write("    scramv1 b ProjectRename\n")
            run_script.write("    scram b clean\n")
            run_script.write("    scram b -j8\n")
            run_script.write("    cd $_CONDOR_SCRATCH_DIR/work\n")
            run_script.write("done\n")
        #run_script.write("env\n")
        command = "source $_CONDOR_SCRATCH_DIR/run.sh {} $_CONDOR_SCRATCH_DIR/{} {} $(($1+{})) filelist:$_CONDOR_SCRATCH_DIR/pileupinput.dat 2>&1 ".format(
            args.name, 
            os.path.basename(fragment_abspath), 
            args.nevents_job,
            args.seed_offset
        )
        run_script.write(command + "\n")
        #run_script.write("source run_BParkingNANO.sh {} $NEVENTS ./*MiniAOD*root".format(args.bnano_cfg))
        run_script.write("mv *py $_CONDOR_SCRATCH_DIR\n")

        if args.outEOS:
            if args.keepNano:
                run_script.write("xrdcp *NanoAOD*root root://eoscms.cern.ch//eos/cms/{} \n".format(args.outEOS))
            if args.keepMini:
                run_script.write("xrdcp *MiniAOD*root root://eoscms.cern.ch//eos/cms/{} \n".format(args.outEOS))
            if args.keepDR:
                run_script.write("xrdcp *DR*root root://eoscms.cern.ch//eos/cms/{} \n".format(args.outEOS))
            if args.keepRECO:
                run_script.write("xrdcp *RECO*root root://eoscms.cern.ch//eos/cms/{} \n".format(args.outEOS))
            if args.keepGS:
                run_script.write("xrdcp *GS*root root://eoscms.cern.ch//eos/cms/{} \n".format(args.outEOS))
        elif args.outcp:
            run_script.write("mkdir -pv {} \n".format(args.outcp))
            if args.keepNano:
                run_script.write("cp *NanoAOD*root {} \n".format(args.outcp))
            if args.keepMini:
                run_script.write("cp *MiniAOD*root {} \n".format(args.outcp))
            if args.keepDR:
                run_script.write("cp *DR*root {} \n".format(args.outcp))
            if args.keepRECO:
                run_script.write("cp *RECO*root {} \n".format(args.outcp))
            if args.keepGS:
                run_script.write("cp *GS*root {} \n".format(args.outcp))
        elif args.gfalcp:
            run_script.write("echo \"Starting gfal-cp from $PWD\n\"")
            run_script.write("echo \"Contents of current directory:\n\"")
            run_script.write("ls -lrth \n")
            run_script.write("scram unsetenv\n")
            if args.keepNano:
                run_script.write("for FILENAME in ./*NanoAOD*root; do\n")
                run_script.write("   echo \"Copying $FILENAME\"\n")
                run_script.write("   env -i bash -l -c \"export X509_USER_PROXY=$_CONDOR_SCRATCH_DIR/x509up; gfal-copy -f -p -v -t 180 file://$PWD/$FILENAME '{}/$FILENAME' 2>&1\"\n".format(args.gfalcp))
                run_script.write("done\n")
            if args.keepMini:
                run_script.write("for FILENAME in ./*MiniAOD*root; do\n")
                run_script.write("   echo \"Copying $FILENAME\"\n")
                run_script.write("   env -i bash -l -c \"export X509_USER_PROXY=$_CONDOR_SCRATCH_DIR/x509up; gfal-copy -f -p -v -t 180 file://$PWD/$FILENAME '{}/$FILENAME' 2>&1\"\n".format(args.gfalcp))
                run_script.write("done\n")
            if args.keepDR:
                run_script.write("for FILENAME in ./*DR*root; do\n")
                run_script.write("   echo \"Copying $FILENAME\"\n")
                run_script.write("   env -i bash -l -c \"export X509_USER_PROXY=$_CONDOR_SCRATCH_DIR/x509up; gfal-copy -f -p -v -t 180 file://$PWD/$FILENAME '{}/$FILENAME' 2>&1\"\n".format(args.gfalcp))
                run_script.write("done\n")
            if args.keepRECO:
                run_script.write("for FILENAME in ./*RECO*root; do\n")
                run_script.write("   echo \"Copying $FILENAME\"\n")
                run_script.write("   env -i bash -l -c \"export X509_USER_PROXY=$_CONDOR_SCRATCH_DIR/x509up; gfal-copy -f -p -v -t 180 file://$PWD/$FILENAME '{}/$FILENAME' 2>&1\"\n".format(args.gfalcp))
                run_script.write("done\n")
            if args.keepGS:
                run_script.write("for FILENAME in ./*GENSIM*root; do\n")
                run_script.write("   echo \"Copying $FILENAME\"\n")
                run_script.write("   env -i bash -l -c \"export X509_USER_PROXY=$_CONDOR_SCRATCH_DIR/x509up; gfal-copy -f -p -v -t 180 file://$PWD/$FILENAME '{}/$FILENAME' 2>&1\"\n".format(args.gfalcp))
                run_script.write("done\n")
        else:
            if args.keepNano:
                run_script.write("mv *NanoAOD*root $_CONDOR_SCRATCH_DIR\n")
            if args.keepMini:
                run_script.write("mv *MiniAOD*root $_CONDOR_SCRATCH_DIR\n")
            if args.keepDR:
                run_script.write("mv *DR*root $_CONDOR_SCRATCH_DIR\n")
            if args.keepRECO:
                run_script.write("mv *RECO*root $_CONDOR_SCRATCH_DIR\n")
            if args.keepGS:
                run_script.write("mv *GS*root $_CONDOR_SCRATCH_DIR\n")
        run_script.write("ls -lrth\n")
        run_script.write("pwd\n")
        run_script.write("ls -lrth $_CONDOR_SCRATCH_DIR\n")


    files_to_transfer = [fragment_abspath, 
                            f"{MYOMCPATH}/campaigns/{args.campaign}/run.sh", 
                            f"{MYOMCPATH}/campaigns/{args.campaign}/pileupinput.dat", 
                        ]
    if args.env:
        files_to_transfer.append(f"{MYOMCPATH}/campaigns/{args.campaign}/env.tar.gz")
    csub_command = "csub runwrapper.sh -t tomorrow --mem 11900 --nCores 8 -F {} --queue_n {} -x $HOME/private/x509up".format(",".join(files_to_transfer), args.njobs) # 
    if not args.os:
        # Infer OS from campaign
        if "RunII" in args.campaign:
            job_os = "SLCern6"
        elif "UL" in args.campaign:
            job_os = "CentOS7"
        else:
            print "Unable to infer OS from campaign {}. Using CC7.".format(args.campaign)
            job_os = "CentOS7"
    else:
        job_os = args.os
    csub_command += " --os {}".format(job_os)
    if args.seed_offset:
        csub_command += " --seed_offset {}".format(args.seed_offset)
    os.system(csub_command)

    os.chdir(cwd)