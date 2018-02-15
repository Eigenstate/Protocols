#!/usr/bin/env python

"""
Obtains the residue names of water, lipid, and protein from an input system
using vmd-python. Output is a set of sed commands that can be invoked on the
skeleton mdin files to set the restraint and shake masks correctly.
"""

import sys
from vmd import atomsel, molecule

if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise ValueError("Incorrect arguments")

    prmtop = sys.argv[1]
    mid = molecule.load("parm7", prmtop)
    result = ""

    # Get the lipid selection. For AMBER, only the head group can be picked up
    # by this, so use the "same fragment" syntax to get the tails, too.
    lipids = set(atomsel("same fragment as lipid", mid).get("resname"))
    lipcommand = "-e \"s/(LIPID)/(:%s)/g\" " % ("|:".join(lipids))
    result += lipcommand

    # Now get all the ions
    ionids = set(atomsel("ion", mid).get("resname"))
    ioncommand = "-e \"s/(ION)/(:%s)/g\" " % ("|:".join(ionids))
    result += ioncommand

    # Now the water residue name
    # Do first with residue prefixes, then without, for more clarity
    # in skeleton input files
    watids = set(atomsel("water", mid).get("resname"))
    if len(watids) > 1:
        raise ValueError("Found more than one water model in use. "
                         "Resames were: '%s'" % ", ".join(watids))
    watcommand = "-e \"s/(WATER)/(:%s)/g\" " % ("|:".join(watids))
    watcommand += "-e \"s/(WATRES)/%s/g\" " % watids.pop()
    result += watcommand

    # Finally, the water oxygen atom name, for shake
    wtoids = set(atomsel("water and element O", mid).get("name"))
    if len(wtoids) > 1:
        raise ValueError("Found more than one water oxygen name. "
                         "Names were: '%s'" % ", ".join(wtoids))
    wtocommand = "-e \"s/(WATERO)/%s/g\" " % wtoids.pop()
    result += wtocommand

    molecule.delete(mid)
    print(result)

