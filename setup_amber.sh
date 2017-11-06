#!/bin/bash

# Use these intel and cuda
if [[ $SHERLOCK == 1 ]]; then

    # Sometimes PI home is unset. Why? I dont know AUGH
    export PI_HOME="/share/PI/rondror"

    # Okay sometimes module command is not defined here. That's dumb
    # Let's setup the module environment manually
    export MODULESHOME=/share/sw/free/lmod/lmod
    export BASH_ENV=$MODULESHOME/init/bash
    export MANPATH=$($MODULESHOME/libexec/addto MANPATH $MODULESHOME/share/man)
    source $BASH_ENV >/dev/null                 # Module Support
    export LMOD_PACKAGE_PATH=/share/sw/modules/ # where SitePackage.lua resides
    export MODULEPATH_ROOT=/share/sw/modules
    export MODULEPATH=/share/sw/modules/Core

    module load intel/2015
    module load cuda/8.0

# For Sherlock 2, the module names are slightly different
elif [[ $SHERLOCK == 2 ]]; then

    module load ifort/2018
    module load icc/2018
    module load imkl/2018
    module load cuda/8.0.61
    module unload openmpi impi

else
    echo "SHERLOCK is unset! Doing nothing"
    return
fi

# Amber wants MKL_HOME defined but module sets MKLROOT
export MKL_HOME=$MKLROOT

# Use our own intel compiled mpich 3.2
export MPI_HOME="$PI_HOME/software/mpich-3.2"            # easier to type, some programs want this set
export MPICC="$MPI_HOME/bin/mpicc"
export MPICXX="$MPI_HOME/bin/mpicxx"
export MPIF77="$MPI_HOME/bin/mpif77"
export MPIF90="$MPI_HOME/bin/mpif90"

export PATH="$MPI_HOME/bin:$PATH"                        # get mpicc etc
export CPATH="$MPI_HOME/include:$CPATH"                  # language independent include path
export LD_LIBRARY_PATH="$MPI_HOME/lib:$LD_LIBRARY_PATH"  # search path at runtime
export LIBRARY_PATH="$MPI_HOME/lib:$LIBRARY_PATH"        # search path at compile time (ld invocation)

# Make -lcuda work as libcuda is in stubs
export LD_LIBRARY_PATH="$CUDA_HOME/lib64/stubs:$LD_LIBRARY_PATH"
export LIBRARY_PATH="$CUDA_HOME/lib64/stubs:$LIBRARY_PATH"

# Set some envs
export AMBERHOME="$PI_HOME/software/amber_dev"
export PATH="$AMBERHOME/bin:$PATH"
export LD_LIBRARY_PATH="$AMBERHOME/lib:$LD_LIBRARY_PATH"

# stupid readline stuff
export CPATH="/usr/include/readline/:$CPATH"
export LD_LIBRARY_PATH="/usr/lib64:$LD_LIBRARY_PATH"


