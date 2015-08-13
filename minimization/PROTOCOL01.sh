#!/bin/bash
#SBATCH --time=48:00:00
#SBATCH --ntasks=1 --cpus-per-task=1
#SBATCH --share
#SBATCH --job-name=minimization
#SBATCH --output=01slurm.out --open-mode=append
#SBATCH --mail-user=robin@robinbetz.com
#
#=====================================================================
#                            PROTOCOL01
#=====================================================================
# GOAL   : Minimize the system 
# INPUTS : 
# OUTPUT : 
# PROJECT: 
# PATH   : 
# DATE   : 
#=====================================================================
#

# Protocol revision number
rev=01

# PRMTOP and INPCRD for generic minimization
prmtop=""
inpcrd=""

# Directory with input files
inpdir="/share/PI/rondror/MD_simulations/amber/robin_D2_dopamine/input_files/minimization"

# Exit if any command fails
set -e

# Load necessary modules
date
module load amber/14-intel

# Minimize holding the protein really fixed and the lipid mostly fixed
echo "First minimization..."
pmemd -O -i "$inpdir/01_min.mdin" -o "${rev}_min1.mdout" -p "$prmtop" \
       -c "$inpcrd" -r "${rev}_min1.rst" -ref "$inpcrd"

# Minimize with slightly weaker restraints
echo "Second minimization..."
pmemd -O -i "$inpdir/02_min.mdin" -o "${rev}_min2.mdout" -p "$prmtop" \
      -c "${rev}_min1.rst" -r "${rev}_min2.rst" -ref "${rev}_min1.rst"

# Minimize with no restraints
echo "Third minimization..."
pmemd -O -i "$inpdir/03_min.mdin" -o "${rev}_min3.mdout" -p "$prmtop" \
      -c "${rev}_min2.rst" -r "${rev}_min3.rst"

echo "Done"
date
