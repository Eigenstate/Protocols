#!/bin/bash

if [[ -z $SHERLOCK ]]; then
    echo "\$SHERLOCK is unset!"
    exit 1
fi

. $PI_HOME/software/submit_new/amber_sherlock${SHERLOCK}.sh

