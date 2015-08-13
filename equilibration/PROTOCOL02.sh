#!/bin/bash
#SBATCH --time=48:00:00
#SBATCH --partition=rondror
#SBATCH --qos=rondror --gres=gpu:2
#SBATCH --ntasks-per-socket=2 --tasks=2
#SBATCH --output=01slurm.out --open-mode=append
#SBATCH --mail-user=robin@robinbetz.com --mail-type=ALL
#SBATCH --job-name=
# If you want to run after a minimization is done, uncomment this
# and put in the job number at the end.
##SBATCH --dependency=afterok:
#
#=====================================================================
#                            PROTOCOL02
#=====================================================================
# GOAL   : Equilibrate the system at 310K after heating
#        
# INPUTS : 
# OUTPUT : 
# PROJECT: 
# PATH   : 
# DATE   : 
#=====================================================================
#

# Protocol revision number
rev=02

# Output from minimization, should be prmtop and min.rst or something
prmtop=""
rst=""

# Directory with input files
inpdir="/share/PI/rondror/MD_simulations/amber/robin_D2_dopamine/input_files/equilibration"

# Exit if any command fails
set -e

# Load necessary modules
date
module load amber/14-cuda

# Heat from 0 to 100K with restraints 10 on the lipid and protein for 12.5ps
# in the NVT ensemble, 2.5fs timsetep
echo "NVT heating..."
mpirun -np 2 --bind-to socket pmemd.cuda.MPI -O -i "$inpdir/02Heat_1.mdin" \
       -o "${rev}Heat_1.mdout" -p "$prmtop" -c "$rst" \
       -r "${rev}Heat_1.rst" -ref "$rst" -x "${rev}Heat_1.nc"

# Heat again from 100 to 310K with restraints 10 on the lipid and protein for
# 125ps in NTP ensemble, 2.5fs timestep
echo "NTP heating..."
mpirun -np 2 --bind-to socket pmemd.cuda.MPI -O -i "$inpdir/02Heat_2.mdin" \
       -o "${rev}Heat_2.mdout" -p "$prmtop" -c "${rev}Heat_1.rst" \
       -r "${rev}Heat_2.rst" -ref "${rev}Heat_1.rst" -x "${rev}Heat_2.nc"

# Equilibrate with restraint 5 on protein only for 2ns
# in the NPT ensemble, 2.5fs timestep
echo "Restraint 5 equilibration..."
mpirun -np 2 --bind-to socket pmemd.cuda.MPI -O -i "$inpdir/02Eq_1.mdin" \
       -o "${rev}Eq_1.mdout" -p "$prmtop" -c "${rev}Heat_2.rst" \
       -r "${rev}Eq_1.rst" -ref "${rev}Heat_2.rst" -x "${rev}Eq_1.nc"

# Decrease restraint on protein to 4 for 2ns
# in the NPT ensemble, 2.5fs timestep
echo "Restraint 4 equilibration..."
mpirun -np 2 --bind-to socket pmemd.cuda.MPI -O -i "$inpdir/02Eq_2.mdin" \
       -o "${rev}Eq_2.mdout" -p "$prmtop" -c "${rev}Eq_1.rst" \
       -r "${rev}Eq_2.rst" -ref "${rev}Eq_1.rst" -x "${rev}Eq_2.nc"

# Decrease restraint on protein to 3 for 2ns
# in the NPT ensemble, 2.5fs timestep
echo "Restraint 3 equilibration..."
mpirun -np 2 --bind-to socket pmemd.cuda.MPI -O -i "$inpdir/02Eq_3.mdin" \
       -o "${rev}Eq_3.mdout" -p "$prmtop" -c "${rev}Eq_2.rst" \
       -r "${rev}Eq_3.rst" -ref "${rev}Eq_2.rst" -x "${rev}Eq_3.nc"

# Decrease restraint on protein to 2 for 2ns
# in the NPT ensemble, 2.5fs timestep
echo "Restraint 2 equilibration..."
mpirun -np 2 --bind-to socket pmemd.cuda.MPI -O -i "$inpdir/02Eq_4.mdin" \
       -o "${rev}Eq_4.mdout" -p "$prmtop" -c "${rev}Eq_3.rst" \
       -r "${rev}Eq_4.rst" -ref "${rev}Eq_3.rst" -x "${rev}Eq_4.nc"

# Decrease restraint on protein to 1 for 2ns
# in the NPT ensemble, 2.5fs timestep
echo "Restraint 1 equilibration..."
mpirun -np 2 --bind-to socket pmemd.cuda.MPI -O -i "$inpdir/02Eq_5.mdin" \
       -o "${rev}Eq_5.mdout" -p "$prmtop" -c "${rev}Eq_4.rst" \
       -r "${rev}Eq_5.rst" -ref "${rev}Eq_4.rst" -x "${rev}Eq_5.nc"

# Remove restraints entirely, equilibrate for 5ns
# in the NPT ensemble, 2.5fs timestep
echo "No restraint equilibration..."
mpirun -np 2 --bind-to socket pmemd.cuda.MPI -O -i "$inpdir/02Eq_6.mdin" \
       -o "${rev}Eq_6.mdout" -p "$prmtop" -c "${rev}Eq_5.rst" \
       -r "${rev}Eq_6.rst" -ref "${rev}Eq_5.rst" -x "${rev}Eq_6.nc"

# Ran the process_mdout.perl script to get statistics about the runs
# Put all the summary files in ${rev}summaries directory
#echo "Processing mdout files"
#process_mdout.perl "${rev}Eq_1.mdout" "${rev}Eq_2.mdout" \
#                   "${rev}Eq_3.mdout" "${rev}Eq_4.mdout" \
#                   "${rev}Eq_5.mdout" "${rev}Eq_6.mdout"
#mkdir "${rev}summaries"
#mv summary.* "${rev}summaries"
#
# Total of 15ns equilibration now performed.
# Relevant output files are the .nc trajectories for analysis
# and the ${rev}Eq_6.rst for use in production simulations
echo "Done"
date
