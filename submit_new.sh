#!/bin/bash

# Check we're on Sherlock
if [[ $(hostname) != *"sherlock"* ]]; then
    echo "Run script on Sherlock, not $(hostname)!"
    exit 1
fi

# Check for skeleton protocols in input files directory
# These should all be here if this script is properly configured
inpdir="/share/PI/rondror/MD_simulations/amber/robin_D2_dopamine/input_files"
if [[ ! -e "$inpdir/minimization/PROTOCOL_skelly" || \
      ! -e "$inpdir/equilibration/PROTOCOL_skelly" || \
      ! -e "$inpdir/production/PROTOCOL_first_skelly" || \
      ! -e "$inpdir/production/PROTOCOL_continue_skelly" ]]; then
    echo "ERROR: Cannot find skeleton input files. Looked in:"
    echo "       $inpdir"
    exit 1
fi

# Prompt for relevant variables echo "Welcome to Robin's job submission script!"
echo "What's the revision?"

read -e rev

echo "What's the path to the simulation root folder? Type PWD for current folder"
read -e dir
if [[ $dir == "PWD" ]]; then dir=$PWD; fi

echo "What's the input prmtop? (Assuming inpcrd is same prefix)"
read -e pre
pre=${pre%.prmtop}

echo "What's a short job name prefix?"
read -e nam

echo "How many replicates should I start?"
read rep

echo "Which queue should I be in? 1 for rondror_high, 2 for rondror, 3 for owners, 4 for shared"
read qos
if [[ "$qos" == "1" ]]; then
  qos="rondror_high"
  part="rondror"
  runtime=8
elif [[ "$qos" == "2" ]]; then
  qos="rondror"
  part="rondror"
  runtime=8
elif [[ "$qos" == "3" ]]; then
  qos="normal"
  part="owners"
  runtime=48
elif [[ "$qos" == "5" ]]; then
  qos="normal"
  part="gpu"
  runtime=48
else exit 1
fi

echo "What is the approximate speed of your simulation, in ns/day?"
read speed
# Calculate number of steps to run with given speed and queue jobstep size
nstep=$(echo "scale=0; $runtime * $speed * 1000000 / 2.5 / 24" | bc) # number of steps
stept=$(echo "scale=0; $runtime * $speed / 24" | bc ) # number of nanoseconds
echo "......That's $stept ns of simulation per jobstep"

echo "How many ns of simulation do you want over all jobsteps?"
read nsec
nruns=$(echo $(printf %.0f $(echo "($nsec/$stept+ 0.5)/1" | bc -l))) # gross bc it needs to round up
echo "  Okay, will submit $nruns jobsteps"

echo "Press 1 for semi-isotropic boundary conditions"
read ntp
if [[ $ntp == "1" ]]; then dirsuf="semiisotropic"
else dirsuf=""; fi

echo "Enter a list of residues to restrain, or press enter"
read restraints
if [[ ! -z "$restraints" ]]; then
  reference=$pre
  if [[ "$ntp" == "1" ]]; then dirsuf="semiisotropic_restrained"
  else
    echo "Sorry, only semi-isotropic restraints currently implemented"
    exit 1
  fi
fi

echo "Press 1 for production runs only"
read prodonly
if [[ $prodonly == "1" ]]; then prodonly="1"
else prodonly="0"; fi

# Create directory structure if nonexistent
echo "Checking directory structure"
if [[ ! -d "$dir" ]]; then mkdir -p $dir; fi
if [[ ! -d "$dir/minimization/$rev" ]]; then mkdir -p "$dir/minimization/$rev"; fi
if [[ ! -d "$dir/equilibration/$rev" ]]; then mkdir -p "$dir/equilibration/$rev"; fi
if [[ ! -d "${dir/share/scratch}" ]]; then mkdir -p "${dir/share/scratch}"; fi

# Make production replicate directories
for ((r=1;r<=$rep;r++)); do
  if [[ ! -d "${dir/share/scratch}/production/$rev/$r" ]]; then mkdir -p "${dir/share/scratch}/production/$rev/$r"; fi
done
if [[ ! -e "$dir/production" ]]; then ln -s "${dir/share/scratch}/production" "$dir/production"; fi
echo "Ok"

# Check that the prmtop and inpcrd exist
echo "Checking for input files..."
prmtop="$dir/${pre}.prmtop"
inpcrd="$dir/${pre}.inpcrd"
if [[ ! -e "$prmtop" || ! -e "$inpcrd" ]]; then
    echo "ERROR: Cannot find prmtop/inpcrd! Names were:"
    echo "       $dir/$pre.prmtop"
    echo "       $dir/$pre.inpcrd" 
    exit 1
fi
echo "Ok"

# Check that the revisions won't overwrite anything
# Don't check for production files since they are auto-appended
echo "Checking for overwrites..."
if [[ $prodonly == "0" ]]; then
    if [[ -e "$dir/minimization/$rev/min1.mdout" || \
          -e "$dir/equilibration/$rev/Eq_1.mdout" ]]; then
        echo "ERROR: Output files found from revision $rev. Won't overwrite."
        exit 1
    fi
fi
echo "Ok"

# Copy input files into simulation directory
prodir="$dir/production/$rev"
cp "$inpdir/production/${dirsuf}/Prod_skelly.mdin" "$prodir/Prod_${runtime}h.mdin"
cp "$inpdir/production/${dirsuf}/Eq_6.mdin" "$prodir"

# Apply number of steps calculated by given speed and queue 
sed -e "s@(NSTEPS)@$nstep@g" -i "$prodir/Prod_${runtime}h.mdin"

# Apply reference string if using restraints
if [[ ! -z "$restraints" ]]; then
  sed -e "s@(REFS)@$restraints@g" -i "$prodir/Eq_6.mdin"
  sed -e "s@(REFS)@$restraints@g" -i "$prodir/Prod_${runtime}h.mdin"
fi

echo
echo "Created input files in $dir/production/$rev"
echo "Edit these files to your specification now."
echo "Press enter to continue"
read sheepity

# Create input files
# Use @ in sed separator because '/' is in some of these variables
if [[ $prodonly == "0" ]]; then
    echo "Creating jobs:"
    echo "Minimization..."
    sed -e "s@(REV)@$rev@g" \
        -e "s@(PRMTOP)@$prmtop@g" \
        -e "s@(INPCRD)@$inpcrd@g" \
        -e "s@(NAM)@$nam@g" \
        -e "s@(NOW)@$(date)@g" \
        -e "s@(QOS)@$qos@g" \
        -e "s@(PART)@$part@g" \
        -e "s@(INP)@$inpdir/minimization@g" \
        -e "s@(DIR)@$dir@g" \
        -e "s@(WHOAMI)@$(whoami)@g" \
        < "$inpdir/minimization/PROTOCOL_skelly" > "$dir/minimization/$rev/PROTOCOL.sh"

    chmod +x "$dir/minimization/$rev/PROTOCOL.sh"
    cd "$dir/minimization/$rev"
    minjob=$(qsub "PROTOCOL.sh")
    cd -

    # Equilibration
    echo "Equilibration..."
    sed -e "s@(REV)@$rev@g" \
        -e "s@(PRMTOP)@$prmtop@g" \
        -e "s@(RST)@${dir}/minimization/$rev/min2.rst@g" \
        -e "s@(DIR)@$dir@g" \
        -e "s@(NAM)@$nam@g" \
        -e "s@(NOW)@$(date)@g" \
        -e "s@(QOS)@$qos@g" \
        -e "s@(PART)@$part@g" \
        -e "s@(INP)@$inpdir/equilibration/${dirsuf}@g" \
        -e "s@(MINNUM)@$minjob@g" \
        -e "s@(P2P)@$inpdir/gpuP2PCheck@" \
        -e "s@(WHOAMI)@$(whoami)@g" \
        < "$inpdir/equilibration/PROTOCOL_skelly" > "$dir/equilibration/$rev/PROTOCOL.sh"

    chmod +x "$dir/equilibration/$rev/PROTOCOL.sh"
    cd "$dir/equilibration/$rev"
    eqjob=$(qsub "PROTOCOL.sh")
    cd -
fi

for ((r=1;r<=$rep;r++)); do
  # Initial production run
  # Check if it's been done yet
  if [[ "$prodonly" == "0" ]]; then
    depline="singleton,afterok:$eqjob"
  else
    depline="singleton"
  fi
  if [[ ! -f "$dir/production/$rev/$r/Prod_0.rst" ]]; then
    # Continue runs will be qsub'd after this one, and 
    # have singleton dependency so will run next.
      sed -e "s@(REV)@$rev@g" \
          -e "s@(PRMTOP)@$prmtop@g" \
          -e "s@(DIR)@$dir@g" \
          -e "s@(NAM)@$nam@g" \
          -e "s@(NOW)@$(date)@g" \
          -e "s@(INP)@$prodir@g" \
          -e "s@(QOS)@$qos@g" \
          -e "s@(PART)@$part@g" \
          -e "s@(REP)@$r@g" \
          -e "s@(P2P)@$inpdir/gpuP2PCheck@g" \
          -e "s@(REFS)@$reference@g" \
          -e "s@(DEPS)@$depline@g" \
          -e "s@(WHOAMI)@$(whoami)@g" \
          -e "s@(RUNTIME)@$runtime@g" \
          < "${inpdir}/production/$dirsuf/PROTOCOL_first_skelly" > "$dir/production/$rev/$r/PROTOCOL_init.sh"

          cd "$dir/production/$rev/$r"
          chmod +x "PROTOCOL_init.sh"
          initprodjob=$(qsub "PROTOCOL_init.sh")
          depline=",afterany:$initprodjob"
          cd -
  else
          depline=""
  fi

  # Production
  echo "Production..."
  declare -a prodjob
    echo "  Replicate $r..."

    sed -e "s@(REV)@$rev@g" \
        -e "s@(PRMTOP)@$prmtop@g" \
        -e "s@(DIR)@$dir@g" \
        -e "s@(NAM)@$nam@g" \
        -e "s@(NOW)@$(date)@g" \
        -e "s@(INP)@$prodir@g" \
        -e "s@(QOS)@$qos@g" \
        -e "s@(PART)@$part@g" \
        -e "s@(INIT)@$depline@g" \
        -e "s@(REP)@$r@g" \
        -e "s@(P2P)@$inpdir/gpuP2PCheck@g" \
        -e "s@(WHOAMI)@$(whoami)@g" \
        -e "s@(RUNTIME)@$runtime@g" \
        < "${inpdir}/production/$dirsuf/PROTOCOL_continue_skelly" > "$dir/production/$rev/$r/PROTOCOL.sh"

    chmod +x "$dir/production/$rev/$r/PROTOCOL.sh"
    # Submit appropriate number of singleton runs
    for ((i=0;i<$((nruns-1));i++)); do
      cd "$dir/production/$rev/$r"
      prodjob[$((rep*(r-1)+i))]=$(qsub "PROTOCOL.sh")
      cd -
    done

done
echo "Ok"

# Print a summary
echo
echo "---------- SUBMISSION SUMMARY ----------"
echo " NAME: $nam"
if [[ $prodonly == "0" ]]; then
    echo " MINIMIZATION:"
    echo "    $minjob"
    echo " EQUILIBRATION: "
    echo "    $eqjob"
fi
echo " PRODUCTION:"
for j in ${initprodjobs[@]}; do
  echo "    $j"
done
for j in ${prodjob[@]}; do
  echo "    $j"
done
echo "----------------------------------------"


