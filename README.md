# Protocols
These are my protocols n they are mine but they can be yours too

## Non-simulations
I organise files by task, in a whole bunch of directories, grouped
by task. As I work I document exactly what I did in a file named PROTOCOL01.txt.

As mistakes are made or I have to redo things for some reason, I go back
to that directory and create a new protocol where I document what I did
differently. That way I have knowledge of what happened at each revision,
and all output files are prefixed with the number of the protocol that
created them.

Use *new\_protocol.sh* to create a protocol of the next available number.
The script will prompt you for information needed to print a pretty
header. I've included an example output here too.

## Simulations
My main script, `submit_new`, will set up and run a new simulation.

## Folder organization
I make one folder for each task, and subfolders for subtasks.
For example, if I am equilibrating a bunch of mutants, I have a folder
called [protein name] with subfolders minimization, equilibration, etc, and
in the equilibration folder there will be folders with the name of each
mutant.

This way I can use common scripts and name everything the same as long as
it stays in its folder.

In the deepest folder there will be a bunch of files and one or more scripts
named PROTOCOL##.sh. This script is run to create all of the output files.

If there are multiple protocol scripts, the one with the largest number
describes the current revision of that protocol, and the previous ones are
kept for historical reasons. All output files will be prefixed by the number
of the protocol that generated them.

The protocol script documents everything that was done in a simulation, step
by step, through a combination of comments and commands. Executing it should
produce exactly the same output each time (w floating point differences).

Files that are taken from one step to another are represented by symlinks in
the directory where they are an input file, pointing to the file that was
created as output by a different task. That way if the dependent task is
redone, the input file is always up to date.

Please talk to me if any of this is unclear.
Lab members, check out my directory in `$PI_HOME` on Sherlock to see how this
is all laid out in practice.

## Files you might want
Protocol files take a long time to write, but generally they are very reuseable
once they are created, especially the simulation scripts. You can find
the ones I use in the simulation/input\_files directory, grouped by task.

There is also a sample protocol file for creating a homology model.
