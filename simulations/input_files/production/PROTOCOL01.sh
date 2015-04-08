#!/bin/bash
#SBATCH --time=160:00:00
#SBATCH --partition=rondror
#SBATCH --qos=rondror --gres=gpu:2
#SBATCH --ntasks-per-socket=1 --tasks=2
#SBATCH --job-name=NAME GOES ERE
#SBATCH --output=01slurm.out
#SBATCH --mail-user=robin@robinbetz.com
#
#=====================================================================
#                            PROTOCOL01
#=====================================================================
# GOAL   : 
# INPUTS : Heated, equilibrated for 3ns system at 310K
# OUTPUT : Trajectory for 100ns of simulation
# PROJECT: 
# PATH   : 
# DATE   : 
#=====================================================================
#

# Protocol revision number
rev=01

# Symlinked the output from previous run to be the input here,
# and symlinked the prmtop from the preparation step
prmtop="PUT PRMTOP HERE"
rst="PUT RST HERE"

# Directory containing mdin files
inpdir="PUT DIRECTOY HERE"

# Exit if any command fails
set -e

# Load necessary modules
module load amber/14-cuda

# Simulate for 100ns at 310K in the NPT ensemble with 2.0fs timestep
# This run will probably run out of walltime.
echo "Beginning 100ns run"
mpirun -np 2 --bind-to socket pmemd.cuda.MPI -O -i "$inpdir/Prod.mdin" \
       -o "${rev}Prod.mdout" -p "$prmtop" -c "$rst" \
       -r "${rev}Prod.rst" -x "${rev}Prod.nc"

# Ran the process_mdout.perl script to get statistics about the runs
# Put all the summary files in 01summaries directory
#echo "Processing mdout files"
#process_mdout.perl "01Eq_1.mdout" "01Eq_2.mdout" \
#                   "01Eq_3.mdout" "01Eq_4.mdout" \
#                   "01Eq_5.mdout" "01Eq_6.mdout"
#mkdir "01summaries"
#mv summary* "01summaries"

# Total of ~100ns equilibration now performed.
# Relevant output file is the 01Prod.nc trajectory and the 01summary files.
echo "Done"

