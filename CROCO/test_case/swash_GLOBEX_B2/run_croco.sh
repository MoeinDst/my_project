#!/bin/bash
#
date
# MoeinDst, 31.05.2025
# ================================================
echo $PATH
echo $LD_LIBRARY_PATH

mkdir -p Output

log_execution_time() {
    duration=$(date -u -d @$(($(date +%s) - start_time)) +"%T")
    echo "Simulation terminated. Total execution time: $duration" >> log_files/run2DV_swash_dx1cm_B2_Rog_frequent.log
    exit
}

# Set the start time                                                                                                               
start_time=$(date +%s)

# Register the signal handler to log the execution time when receiving termination signals                                         
trap log_execution_time SIGINT SIGTERM

# Run the executable and measure the execution time, redirecting output to the log file
mpirun -np 28 ./croco croco.in.Swash2DV_dx1cm_B2 > log_files/run2DV_swash_dx1cm_B2_Rog_frequent.log 2>&1 &

# Get the process ID of the executable    
pid=$!

# Function to check if the process is still running
is_process_running() {
    ps -p $1 > /dev/null
}

# Check if the program finished or was terminated
while true; do
    if ! is_process_running $pid; then
        break
    fi
    sleep 1
done

# Check if the program was terminated
if [ $? -eq 0 ]; then
    # The program finished normally                                                                                                
    duration=$(date -u -d @$(($(date +%s) - start_time)) +"%T")
    echo "Simulation ended. Total execution time: $duration" >> log_files/run2DV_swash_dx1cm_B2_Rog_frequent.log
fi
#
date
