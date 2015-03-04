#!/bin/bash
#
# stickyKeysHunter.sh
# Copyright (c) 2015 Zach Grace
# License: GPLv3
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

if [ -z $1 ]; then
    echo "Usage: $0 target.ip"
    exit 1 
fi

# Configurable options
output="output"
rdesktopSleep=4
stickyKeysSleep=10
host=$1
blue="\e[34m[*]\e[0m"
red="\e[31m[*]\e[0m"
green="\e[32m[*]\e[0m"
temp="/tmp/${host}.$$.png"

function screenshot {
    screenshot=$1
    window=$2
    echo -e "${blue} Saving screenshot to ${screenshot}"
    import -window ${window} "${screenshot}"
}

# Launch rdesktop in the background
echo -e "${blue} Initiating rdesktop connection to ${host}"
export DISPLAY=:0
rdesktop -u "" $host &
sleep $rdesktopSleep # Wait for rdesktop to launch

window=$(xdotool search --name rdesktop)
if [ "${window}" = "" ]; then
    echo -e "${red} Error retrieving window id for rdesktop"
else
    # Set our focus to the RDP window
    echo -e "${blue} Setting window focus to ${window}"
    xdotool windowfocus "${window}"

    # Take a "before" screenshot
    #screenshot "${temp}" "${window}"

    # Send the shift key 5 times to trigger
    echo -e "${blue} Attempting to trigger sethc.exe backdoor"
    xdotool search --class rdesktop key shift shift shift shift shift

    # Send the shift key 5 times to trigger
    echo -e "${blue} Attempting to trigger utilman.exe backdoor"
    xdotool search --class rdesktop key super+u # Windows key + U

    # Seems to be a delay if cmd.exe is set as the debugger this probably needs some tweaking
    echo -e "${blue} waiting ${stickyKeysSleep} seconds for the backdoors to trigger"
    sleep $stickyKeysSleep

    # Screenshot the window using imagemagick
    if [ ! -d "${output}" ]; then
        mkdir "${output}"
    fi

    afterScreenshot="output/${host}.png"
    screenshot "${afterScreenshot}" "${window}"
    
    # Close the rdesktop window
    killall rdesktop 2>/dev/null

    # TODO OCR recognition
    #awk '{sub(/\(/,"", $2); sub(/\)/, "", $2); print $2 * 100}'
    if [ $(convert "${afterScreenshot}" -colors 5 -unique-colors txt:- | grep -c "#000000") -gt 0 ]; then
        echo -e "$green ${host} may have a backdoor"
    else
        echo -e "$blue ${host} may not have a backdoor"
    fi

    # Remove temp file
    #rm "#{temp}"
fi
