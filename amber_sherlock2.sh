#!/bin/bash

# Sherlock 2, GCC build of Amber17 + patches
#  Created at Mon Dec 11 17:01:06 PST 2017 via ./configure -noX11 --skip-python -nofftw3 -mpi -cuda gnu
# Serial ambertools configured with /configure -noX11 --skip-python -nofftw3  gnu  

# Built 11 Dec 2017, RMB
# No effort made for Sherlock 1

module unload icc ifort imkl
module load devel

# Pinned these versions so openmpi can't pull in CUDA 9 - 23 Oct 2018, RMB
module load cuda/8.0.61
module load openmpi/2.1.1

# gcc + openmpi
export MPI_HOME="/share/software/user/open/openmpi/2.1.1/"
export PATH="$MPI_HOME/bin:$PATH"                        # get mpicc etc
export CPATH="$MPI_HOME/include:$CPATH"                  # language independent include path
export LD_LIBRARY_PATH="$MPI_HOME/lib64:$LD_LIBRARY_PATH"  # search path at runtime
export LIBRARY_PATH="$MPI_HOME/lib64:$LIBRARY_PATH"     # search path at compile time (ld invocation)

# Make -lcuda work
export LD_LIBRARY_PATH="$CUDA_HOME/lib64/stubs:$LD_LIBRARY_PATH"
export LIBRARY_PATH="$CUDA_HOME/lib64/stubs:$LIBRARY_PATH"

# Set some envs
export AMBERHOME="$PI_HOME/software/amber16_gnu"
export PATH="$AMBERHOME/bin:$PATH"
export LD_LIBRARY_PATH="$AMBERHOME/lib:$LD_LIBRARY_PATH"
export LD_LIBRARY_PATH="$AMBERHOME/lib64:$LD_LIBRARY_PATH"

# Debugging options
#export FOR_DUMP_CORE_FILE=1
#export FORT_BUFFERED=0
#ulimit -c unlimited
