import sys

num_lines = int(sys.argv[1])

err = False
spike_lines = ""
golden_spike_lines = ""
with open("sim/commit.log") as spike:
    spike_lines = spike.readlines()
with open("sim/spike.log") as golden_spike:
    golden_spike_lines = golden_spike.readlines()

if(num_lines == 0):
    print("setting num_lines to compare all lines in spike/goldenspike")
    num_lines = min(len(spike_lines), len(golden_spike_lines))

for i in range(num_lines):
    if(spike_lines[i] != golden_spike_lines[i]):
        print("Difference found at line", i, "\nSpike: ", spike_lines[i], "\nGolden:", golden_spike_lines[i])
        err = True
        break

if(not err):
    print("No difference found at line", num_lines, "or before.")