import json
import sys
import os

os.chdir(os.path.dirname(os.path.abspath(__file__)))
os.chdir("..")

with open("options.json") as f:
    j = json.load(f)

if "fpga_clock" not in j:
    print('key "fpga_clock" not in options.json', file=sys.stderr)
    exit(1)

print(int(j["fpga_clock"]))
