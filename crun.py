#!/usr/bin/env python
# Run gridpack to NANO on condor

import os
import sys

if __name__ == "__main__":
	import argparse
	parser = argparse.ArgumentParser(description="Run gridpack to NANO on condor")
	parser.add_argument("name", type=str, help="Name of output folder (will be created in current directory)")
	parser.add_argument("fragment", type=str, help="Path to fragment")
	parser.add_argument("campaign", type=str, help="Name of campaign")
	#parser.add_argument("bnano_cfg", type=str, help="Name of BParkingNano cfg")
	parser.add_argument("--nevents_job", type=int, default=100, help="Number of events per job")
	parser.add_argument("--njobs", type=int, default=1, help="Number jobs")
	parser.add_argument("--keepNano", action='store_true', help="Keep NanoAOD")
	parser.add_argument("--keepMini", action='store_true', help="Keep MiniAOD")
	parser.add_argument("--keepDR", action='store_true', help="Keep DR")
	parser.add_argument("--keepRECO", action='store_true', help="Keep RECO")
	parser.add_argument("--keepGS", action='store_true', help="Keep GS")
	parser.add_argument("--outEOS", type=str, help="Transfer files to EOS instead of back to AFS")
	parser.add_argument("--outcp", type=str, help="Transfer output files with cp")
	args = parser.parse_args()

	# Campaign mapping
	if args.campaign == "RunIIFall18GS":
		runscript = "run_Fall18GS.sh"
		pileupfile = "pileup_RunIIFall18GS.dat"
	elif args.campaign == "RunIIFall18GSBParking":
		runscript = "run_Fall18GSBParking.sh"
		pileupfile = "pileup_RunIIFall18GSBParking.dat"
	else:
		raise ValueError("Unknown campaign: {}".format(args.campaign))

	# Check fragment exists
	fragment_abspath = os.path.abspath(args.fragment)
	if not os.path.isfile(fragment_abspath):
		raise ValueError("Couldn't find fragment at {}".format(fragment_abspath))
	print "Using fragment at {}".format(fragment_abspath)

	# For args.outEOS, make sure it's formatted correctly
	if args.outEOS:
		if args.outEOS[:6] != "/store":
			raise ValueError("Argument --outEOS must start with /store (you specified --outEOS {})".format(args.outEOS))
		if not os.path.isdir("/eos/uscms/{}".format(args.outEOS)):
			raise ValueError("Output EOS directory does not exist! (you specified --outEOS {}_".format(args.outEOS))

	# Create and move to working directory
	if os.path.isdir(args.name):
		raise ValueError("Output directory {} already exists!".format(args.name))
	os.system("mkdir -pv {}".format(args.name))
	cwd = os.getcwd()
	os.chdir(args.name)

	# Submit to condor
	with open("run.sh", 'w') as run_script:
		run_script.write("#!/bin/bash\n")
		run_script.write("ls -lrth\n")
		run_script.write("pwd\n")
		run_script.write("mkdir work\n")
		run_script.write("cd work\n")
		#run_script.write("env\n")
		command = "source $_CONDOR_SCRATCH_DIR/{} {} $_CONDOR_SCRATCH_DIR/{} {} $1 filelist:$_CONDOR_SCRATCH_DIR/{} 2>&1 ".format(
			runscript,
			args.name, 
			os.path.basename(fragment_abspath), 
			args.nevents_job,
			os.path.basename(pileupfile)
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


	files_to_transfer = [fragment_abspath, "/user_data/dryu/BFrag/gen/scripts/{}".format(runscript), "/user_data/dryu/BFrag/gen/scripts/{}".format(pileupfile), "/user_data/dryu/BFrag/gen/scripts/run_BParkingNANO.sh"]
	csub_command = "csub run.sh -t tomorrow -F {} --queue_n {} -x $HOME/private/x509up_u3830".format(",".join(files_to_transfer), args.njobs) # 
	os.system(csub_command)

	os.chdir(cwd)