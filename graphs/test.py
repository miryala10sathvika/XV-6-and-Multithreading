import matplotlib.pyplot as plt

# Read data from file
with open('/home/sathvika/mini-project-3-miryala10sathvika/graphs/data.txt', 'r') as file:
    data = file.read()

# Parse the data and extract pid and clock ticks
pid_ticks = [(int(line.split()[1]), int(line.split()[-1])) for line in data.strip().split("\n")]

# Filter out processes with pid <= 3
filtered_pid_ticks = [(pid, ticks) for pid, ticks in pid_ticks if pid > 3]

# Adjust the y-axis values for pid == 4 and above
adjusted_pids = [pid - 4 for pid, _ in filtered_pid_ticks]

# Separate pid and ticks into separate lists
adjusted_ticks = [ticks for _, ticks in filtered_pid_ticks]

# Create a dictionary to map each pid to a unique color
pid_color_mapping = {pid: f'C{i}' for i, pid in enumerate(set(adjusted_pids))}

# Map colors to each pid
colors = [pid_color_mapping[pid] for pid in adjusted_pids]

# Plot the scatter graph with different colors for each pid
scatter = plt.scatter(adjusted_ticks, adjusted_pids, c=colors, marker='o')

# Create legend at the top right
legend_elements = [plt.Line2D([0], [0], marker='o', color='w', markerfacecolor=pid_color_mapping[pid], markersize=10, label=f'PID {pid}') for pid in set(adjusted_pids)]
plt.legend(handles=legend_elements, title='Legend', loc='upper right')

plt.title('Scatter Plot between PID and Clock Ticks PBS(SET 1)')
plt.xlabel('Clock Ticks')
plt.ylabel('Adjusted Process ID (PID)')
plt.grid(True)
plt.show()
