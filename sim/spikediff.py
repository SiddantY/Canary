import sys

# Read the first command-line argument
file_selection = int(sys.argv[1])  # 0 or 1 to select the file

# Select the appropriate commit log file based on the first argument
if file_selection == 0:
    commit_log_file = "sim/commit.log"
elif file_selection == 1:
    commit_log_file = "sim/commit1.log"
else:
    print("Invalid argument. Please provide 0 or 1 as the first argument.")
    sys.exit(1)

# Read the second command-line argument as the number of lines to compare
num_lines = int(sys.argv[2])

err = False
spike_lines = ""
golden_spike_lines = ""

# Open the selected commit log file
with open(commit_log_file) as spike:
    spike_lines = spike.readlines()

# Open the golden spike log file
with open("sim/spike.log") as golden_spike:
    golden_spike_lines = golden_spike.readlines()

# Set num_lines to compare all lines if 0 is provided
if num_lines == 0:
    print("Setting num_lines to compare all lines in spike/golden spike.")
    num_lines = min(len(spike_lines), len(golden_spike_lines))

# Compare the specified number of lines
for i in range(num_lines):
    if spike_lines[i] != golden_spike_lines[i]:
        print("Difference found at line", i, "\nSpike: ", spike_lines[i], "\nGolden:", golden_spike_lines[i])
        err = True
        break

if not err:
    print("No difference found at line", num_lines, "or before.")
