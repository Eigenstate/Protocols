#!/bin/bash
#
#    Creates a new protocol in the current folder, and prompts
#    for basic information about it.
#
#    Copyright (C) 2015 Robin M. Betz
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License along
#    with this program; if not, write to the Free Software Foundation, Inc.,
#    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

# Determine which protocol we're on
i=1
protocol="PROTOCOL$(printf "%02d" $i).txt"
while [[ -f "$protocol" ]]; do
  (( i++ ))
  protocol="PROTOCOL$(printf "%02d" $i).txt"
done

# Prompt the user for header information
echo "GOAL? "
read goal

echo "INPUTS? "
read inputs

echo "OUTPUT? "
read output

echo "PROJECT? "
read project

cat > $protocol << EOF
=====================================================================
                           ${protocol%.txt} 
=====================================================================
GOAL   : $goal
INPUTS : $inputs
OUTPUT : $output
PROJECT: $project
PATH   : $PWD
DATE   : $(date +"%d %B %y")
=====================================================================

EOF

echo "Wrote file $protocol"

