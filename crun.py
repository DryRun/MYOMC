#!/usr/bin/env python3
# Run gridpack to NANO on condor

import os
import sys
import subprocess
import socket

hostname = socket.gethostname()
print(f"Detected host {hostname}")
if "cmslpc" in hostname:
    host = "cmslpc"
elif "lxplus" in hostname:
    host = "lxplus"
elif "uscms" in hostname:
    host = "cmsconnect"
else:
    raise ValueError("Unknown host {}".format(hostname))


MYOMCPATH = os.getenv("MYOMCPATH")
if not MYOMCPATH:
    raise ValueError("Environment variable MYOMCPATH must be set. Call env.sh.")

def make_proxy(proxy_path):
    os.system("voms-proxy-init -voms cms -out {} -valid 72:00".format(proxy_path))

def get_proxy_lifetime(proxy_path):
    import subprocess
    lifetime = float(subprocess.check_output("voms-proxy-info -timeleft -file {}".format(proxy_path), shell=True).strip())
    print("Proxy remaining lifetime: {}".format(lifetime))
    return lifetime

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Run gridpack to NANO on condor")
    parser.add_argument("name", type=str, help="Name of output folder (will be created in current directory)")
    parser.add_argument("fragment", type=str, help="Path to fragment")
    parser.add_argument("campaign", type=str, help="Name of campaign")
    parser.add_argument("--env", "-e", action="store_true", help="Use pre-packaged CMSSW environments (run setup_env.sh first)")
    parser.add_argument("--pileup_file", "-p", action="store_true", help="Use premade pileup input file instead of DAS query (saves some time)")
    parser.add_argument("--nevents_job", type=int, default=100, help="Number of events per job")
    parser.add_argument("--njobs", type=int, default=1, help="Number jobs")
    parser.add_argument("--keepNANOGEN", action="store_true", help="Keep NANOGEN")
    parser.add_argument("--keepNANO", action='store_true', help="Keep NanoAOD")
    parser.add_argument("--keepMINI", action='store_true', help="Keep MiniAOD")
    parser.add_argument("--keepDR", action='store_true', help="Keep DR")
    parser.add_argument("--keepRECO", action='store_true', help="Keep RECO")
    parser.add_argument("--keepGS", action='store_true', help="Keep GS")
    parser.add_argument("--keepwmLHE", action='store_true', help="Keep wmLHE")
    parser.add_argument("--outEOS", type=str, help="Transfer files to EOS instead of back to AFS")
    parser.add_argument("--outcp", type=str, help="Transfer output files with cp")
    parser.add_argument("--gfalcp", type=str, help="Transfer output files with gfalcp")
    #parser.add_argument("--os", type=str, help="Force SLC6 or CC7 (might not work!)")
    parser.add_argument("--seed_offset", type=int, default=0, help="Offset random seed (useful for extending previous runs)")
    parser.add_argument("--mem", type=int, default=7900, help="Memory to request")
    parser.add_argument("--max_nthreads", type=int, default=8, help="Maximum number of threads (reduce if condor priority is a problem)")
    parser.add_argument("--overwrite", "-f", action="store_true", help="Force overwrite outputs")
    args = parser.parse_args()

    # Campaign check
    if not args.campaign in ["RunIIFall18GS", "RunIIFall18GSBParking", "RunIISummer20UL17wmLHE", "NANOGEN"]:
        raise ValueError("Unknown campaign: {}".format(args.campaign))

    # Check fragment exists
    fragment_abspath = os.path.abspath(args.fragment)
    if not os.path.isfile(fragment_abspath):
        raise ValueError("Couldn't find fragment at {}".format(fragment_abspath))
    print("Using fragment at {}".format(fragment_abspath))

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
    #if args.os:
    #    if not args.os in ["SLCern6", "CentOS7"]:
    #        raise ValueError("--os must be SLCern6 or CentOS7.")

    # For args.outEOS, make sure it's formatted correctly, and make sure output dir exists
    if args.outEOS:
        if args.outEOS[:6] != "/store" and args.outEOS[:5] != "/user":
            raise ValueError("Argument --outEOS must start with /store or /user (you specified --outEOS {})".format(args.outEOS))
        #if not os.path.isdir("/eos/uscms/{}".format(args.outEOS)):
        #    raise ValueError("Output EOS directory does not exist! (you specified --outEOS {}_".format(args.outEOS))
        if not args.outEOS[-1] == "/":
            args.outEOS += "/"

        # Determine eos prefix
        if args.outEOS[:6] == "/store" and host == "lxplus":
            eos_prefix = "root://eoscms.cern.ch/"
        elif args.outEOS[:5] == "/user" and host == "lxplus":
            eos_prefix = "root://eosuser.cern.ch/"
        elif host == "cmslpc":
            eos_prefix = "root://cmseos.fnal.gov"
        elif host == "cmsconnect":
            eos_prefix = "root://cmseos.fnal.gov"
        else:
            raise ValueError("Unable to determine EOS prefix")

        # Create output directory
        if host == "lxplus" or host == "cmslpc":
            import subprocess
            subp = subprocess.Popen("eos {} ls {}".format(eos_prefix, args.outEOS).split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            stdout, stderr = subp.communicate()
            if subp.returncode == 0:
                print("WARNING : EOS output directory {} already exists! Writing to existing directory, but be careful.".format(args.outEOS))
            else:
                print("Creating EOS output directory {}".format(args.outEOS))
                print("eos {} mkdir -p {}".format(eos_prefix, args.outEOS))
                subp = subprocess.Popen("eos {} mkdir {}".format(eos_prefix, args.outEOS).split(" "), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                stdout, stderr = subp.communicate()
                print(stdout)
                print(stderr)
        elif host == "cmsconnect":
            # Use gfal instead of eos
            gfal_dir = f"gsiftp://cmseos-gridftp.fnal.gov//eos/uscms/{args.outEOS}"
            import subprocess
            subp = subprocess.Popen(f"gfal-ls {gfal_dir}".split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            stdout, stderr = subp.communicate()
            if subp.returncode == 0:
                print("WARNING : EOS output directory {} already exists! Writing to existing directory, but be careful.".format(args.outEOS))
            else:
                print("Creating EOS output directory {}".format(args.outEOS))
                subp = subprocess.Popen(f"gfal-mkdir -p {gfal_dir}".split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                stdout, stderr = subp.communicate()
                print(stdout)
                print(stderr)

    # Create and move to working directory
    csub_dir = "{}/{}".format(args.name, args.campaign)
    if os.path.isdir(csub_dir) and not args.overwrite:
        raise ValueError("Working directory {} already exists! Specify -f to overwrite".format(csub_dir))
    os.system("mkdir -pv {}".format(csub_dir))
    cwd = os.getcwd()
    os.chdir("{}".format(csub_dir))

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
            #run_script.write("    scram b clean\n")
            #run_script.write("    scram b -j8\n")
            run_script.write("    cd $_CONDOR_SCRATCH_DIR/work\n")
            run_script.write("done\n")
        #run_script.write("env\n")
        command = "source $_CONDOR_SCRATCH_DIR/run.sh {} $_CONDOR_SCRATCH_DIR/{} {} $(($1+{})) {} ".format(
            args.name, 
            os.path.basename(fragment_abspath), 
            args.nevents_job,
            args.seed_offset,
            args.max_nthreads
        )
        if args.pileup_file:
            command += " $_CONDOR_SCRATCH_DIR/pileupinput.dat"
        command += " 2>&1"
        run_script.write(command + "\n")
        #run_script.write("source run_BParkingNANO.sh {} $NEVENTS ./*MiniAOD*root".format(args.bnano_cfg))
        run_script.write("mv *py $_CONDOR_SCRATCH_DIR\n")

        if args.outEOS:
            if args.keepNANOGEN:
                run_script.write("xrdcp -p -f *NANOGEN*root {}/{} \n".format(eos_prefix, args.outEOS))
            if args.keepNANO:
                run_script.write("xrdcp -p -f *NANOAOD*root {}/{} \n".format(eos_prefix, args.outEOS))
            if args.keepMINI:
                run_script.write("xrdcp -p -f *MINIAOD*root {}/{} \n".format(eos_prefix, args.outEOS))
            if args.keepDR:
                run_script.write("xrdcp -p -f *DR*root {}/{} \n".format(eos_prefix, args.outEOS))
            if args.keepRECO:
                run_script.write("xrdcp -p -f *RECO*root {}/{} \n".format(eos_prefix, args.outEOS))
            if args.keepGS:
                run_script.write("xrdcp -p -f *GS*root {}/{} \n".format(eos_prefix, args.outEOS))
            if args.keepwmLHE:
                run_script.write("xrdcp -p -f *wmLHE*root {}/{} \n".format(eos_prefix, args.outEOS))
        elif args.outcp:
            run_script.write("mkdir -pv {} \n".format(args.outcp))
            if args.keepNANOGEN:
                run_script.write("cp *NANOGEN*root {} \n".format(args.outcp))
            if args.keepNANO:
                run_script.write("cp *NanoAOD*root {} \n".format(args.outcp))
            if args.keepMINI:
                run_script.write("cp *MiniAOD*root {} \n".format(args.outcp))
            if args.keepDR:
                run_script.write("cp *DR*root {} \n".format(args.outcp))
            if args.keepRECO:
                run_script.write("cp *RECO*root {} \n".format(args.outcp))
            if args.keepGS:
                run_script.write("cp *GS*root {} \n".format(args.outcp))
            if args.keepwmLHE:
                run_script.write("cp *wmLHE*root {} \n".format(args.outcp))
        elif args.gfalcp:
            run_script.write("echo \"Starting gfal-cp from $PWD\n\"")
            run_script.write("echo \"Contents of current directory:\n\"")
            run_script.write("ls -lrth \n")
            run_script.write("scram unsetenv\n")
            if args.keepNANOGEN:
                run_script.write("for FILENAME in ./*NANOGEN*root; do\n")
                run_script.write("   echo \"Copying $FILENAME\"\n")
                run_script.write("   env -i bash -l -c \"export X509_USER_PROXY=$_CONDOR_SCRATCH_DIR/x509up; gfal-copy -f -p -v -t 180 file://$PWD/$FILENAME '{}/$FILENAME' 2>&1\"\n".format(args.gfalcp))
                run_script.write("done\n")
            if args.keepNANO:
                run_script.write("for FILENAME in ./*NanoAOD*root; do\n")
                run_script.write("   echo \"Copying $FILENAME\"\n")
                run_script.write("   env -i bash -l -c \"export X509_USER_PROXY=$_CONDOR_SCRATCH_DIR/x509up; gfal-copy -f -p -v -t 180 file://$PWD/$FILENAME '{}/$FILENAME' 2>&1\"\n".format(args.gfalcp))
                run_script.write("done\n")
            if args.keepMINI:
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
            if args.keepwmLHE:
                run_script.write("for FILENAME in ./*wmLHE*root; do\n")
                run_script.write("   echo \"Copying $FILENAME\"\n")
                run_script.write("   env -i bash -l -c \"export X509_USER_PROXY=$_CONDOR_SCRATCH_DIR/x509up; gfal-copy -f -p -v -t 180 file://$PWD/$FILENAME '{}/$FILENAME' 2>&1\"\n".format(args.gfalcp))
                run_script.write("done\n")
        else:
            if args.keepNANOGEN:
                run_script.write("mv *NANOGEN*root $_CONDOR_SCRATCH_DIR\n")
            if args.keepNANO:
                run_script.write("mv *NanoAOD*root $_CONDOR_SCRATCH_DIR\n")
            if args.keepMINI:
                run_script.write("mv *MiniAOD*root $_CONDOR_SCRATCH_DIR\n")
            if args.keepDR:
                run_script.write("mv *DR*root $_CONDOR_SCRATCH_DIR\n")
            if args.keepRECO:
                run_script.write("mv *RECO*root $_CONDOR_SCRATCH_DIR\n")
            if args.keepGS:
                run_script.write("mv *GS*root $_CONDOR_SCRATCH_DIR\n")
            if args.keepwmLHE:
                run_script.write("mv *wmLHE*root $_CONDOR_SCRATCH_DIR\n")
        run_script.write("ls -lrth\n")
        run_script.write("pwd\n")
        run_script.write("ls -lrth $_CONDOR_SCRATCH_DIR\n")


    files_to_transfer = [fragment_abspath, 
                            "{}/{}/run.sh".format(MYOMCPATH, args.campaign), 
                        ]
    if args.pileup_file:
        files_to_transfer.append("{}/{}/pileupinput.dat".format(MYOMCPATH, args.campaign))
    if args.env:
        files_to_transfer.append("{}/{}/env.tar.gz".format(MYOMCPATH, args.campaign))
    csub_command = "csub runwrapper.sh -t tomorrow --mem {} --nCores {} -F {} --queue_n {} -x $HOME/private/x509up".format(
                        args.mem,
                        args.max_nthreads, 
                        ",".join(files_to_transfer), 
                        args.njobs) # 
    '''
    if not args.os:
        # Infer OS from campaign
        if "RunII" in args.campaign and not "UL" in args.campaign:
            job_os = "SLCern6"
        elif "UL" in args.campaign:
            job_os = "CentOS7"
        elif args.campaign == "NANOGEN":
            job_os = "SLCern6"
        else:
            print "Unable to infer OS from campaign {}. Using CC7.".format(args.campaign)
            job_os = "CentOS7"
    else:
        job_os = args.os
    print("Using OS {}".format(job_os))
    csub_command += " --os {}".format(job_os)
    '''
    os.system(csub_command)

    os.chdir(cwd)