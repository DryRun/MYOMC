import yaml
from pprint import pprint

with open('campaign.yml', 'r') as file:
	campaign_cfg = yaml.safe_load(file)
pprint(campaign_cfg)
for step in campaign_cfg["steps"]:
	print(step["name"])
	print(step["cmsdriver"])
