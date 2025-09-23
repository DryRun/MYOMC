#!/bin/env python3

def campaign_path(yml):
	campaign_name = yml["name"]
	campaign_path = os.path.join(os.environ("MYOMCPATH"), "campaigns", campaign_name)

def create_setup_file(yml):


def create_run_file(yml):


def 

if __name__ == "__main__":
	parser = argparse.ArgumentParser(description="Setup a new campaign, starting from a campaign yaml file")
	parser.add_argument("campaign_yml", type=str, help="Path to campaign yaml file")
	args = parser.parse_args()

	campaign_yml = args.campaign_yml
	if not os.isfile(campaign_yml): 
		raise FileNotFoundError(f"{campaign_yml} not found")

	with open(campaign_yml, "r") as f:
		campaign_cfg = yaml.safe_load(f)

