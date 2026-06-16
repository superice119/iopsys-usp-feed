#!/bin/sh

# Function to execute commands and append outputs to the log file
execute_commands() {
	log_path="$1"  # Log file path
	cmd="$2"       # Command

	echo "Output of command: $cmd" >> "$log_path"
	$cmd >> "$log_path" 2>&1
	echo "" >> "$log_path"
}

# Function to generate a critical state log
generate_critical_log() {
	log_path="$1"          # Path to the log file
	log_name="$2"          # Name of the critical state (CPU or Memory)
	critical_state="$3"    # Boolean-like string to indicate critical state ("true" or "false")

	# Get the current time in a formatted way
	log_time=$(date "+%Y-%m-%d %H:%M:%S")

	# Determine critical state description
	if [ "$critical_state" = "true" ]; then
		state_desc="Reached"
	else
		state_desc="No Longer Present"
	fi

	# Write the log header with a timestamp
	echo "=== $log_name Critical State $state_desc at $log_time ===" >> "$log_path"
	echo "Running diagnostic commands..." >> "$log_path"

	# Common commands for CPU and Memory
	execute_commands "$log_path" "top -b -n 1"
	execute_commands "$log_path" "free"

	# Add specific commands based on the critical state type
	if [ "$log_name" = "CPU" ]; then
		execute_commands "$log_path" "ps"
	elif [ "$log_name" = "Memory" ]; then
		execute_commands "$log_path" "df -h"
	fi

	# End of log entry
	echo "=== End of Critical $log_name Log ===" >> "$log_path"
	echo "" >> "$log_path"

	# Echo a success message to indicate script completion
	echo "Success: Log generation completed successfully."
}

# Main script logic
if [ "$#" -ne 3 ]; then
	echo "Usage: $0 <type: CPU|Memory> <log_file_path> <critical_state: true|false>"
	exit 1
fi

type="$1"           # First argument: type of critical state (CPU or Memory)
log_file_path="$2"  # Second argument: path to log file
critical_state="$3" # Third argument: critical state indicator ("true" or "false")

# Validate the critical state type
if [ "$type" != "CPU" ] && [ "$type" != "Memory" ]; then
	echo "Invalid type: $type. Must be 'CPU' or 'Memory'."
	exit 1
fi

# Validate the log file directory before proceeding
log_file_dir=$(dirname "$log_file_path")
if [ ! -d "$log_file_dir" ]; then
	echo "Error: Directory $log_file_dir does not exist"
	exit 1
fi

# Create log file if it doesn't exist
if [ ! -f "$log_file_path" ]; then
	touch "$log_file_path"
fi

# Generate the log
generate_critical_log "$log_file_path" "$type" "$critical_state"

# Exit with success code
exit 0
