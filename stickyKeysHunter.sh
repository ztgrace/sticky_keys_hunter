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
rdesktopSleep=10 # Adjust the rdesktopSleep to a larger value if you're getting a lot of black screenshots.
stickyKeysSleep=10
timeout=30
host=$1
blue="\e[34m[*]\e[0m"
red="\e[31m[*]\e[0m"
green="\e[32m[*]\e[0m"
temp="/tmp/${host}.png"

function screenshot {
    screenshot=$1
    window=$2
    echo -e "${blue} Saving screenshot to ${screenshot}"
    import -window ${window} "${screenshot}"
}

# Launch rdesktop in the background
echo -e "${blue} Initiating rdesktop connection to ${host}"
export DISPLAY=:0
rdesktop -u "" -a 16 $host &
pid=$!
sleep $rdesktopSleep # Wait for rdesktop to launch


window=$(xdotool search --name ${host})
if [ "${window}" = "" ]; then
    echo -e "${red} Error retrieving window id for rdesktop"
else
    # Set our focus to the RDP window
    #echo -e "${blue} Setting window focus to ${window}"
    #xdotool windowfocus "${window}"

    # If the screen is all black delay 10 seconds
    timer=0
    while true; do
        # Make sure the process didn't die
        kill -0 $pid
        if [ $? -eq 1 ]; then
            echo -e "${red} Failed to connect to ${host}"
            exit 1
        elif [ $timer -ge $timeout ]; then
            echo -e "${red} Timed out connecting to ${host}"
            exit 1
        fi
        # Screenshot the window and if the only one color is returned (black), give it chance to finish loading
        screenshot "${temp}" "${window}"
        colors=$(convert "${temp}" -colors 5 -unique-colors txt:- | grep -v ImageMagick)
        if [ $(echo "${colors}" | wc -l) -eq 1 ]; then
            echo -e "${blue} Waiting on desktop to load"
            sleep 10
        else
            # Many colors should mean we've got a colsole loaded
            break
        fi
        timer=$((timer + 10))
    done
    rm ${temp}

    # Send the shift key 5 times to trigger
    echo -e "${blue} Attempting to trigger sethc.exe backdoor"
    xdotool key --window ${window} shift shift shift shift shift

    # Send the shift key 5 times to trigger
    echo -e "${blue} Attempting to trigger utilman.exe backdoor"
    xdotool key --window ${window} super+u # Windows key + U

    # Seems to be a delay if cmd.exe is set as the debugger this probably needs some tweaking
    echo -e "${blue} Waiting ${stickyKeysSleep} seconds for the backdoors to trigger"
    sleep $stickyKeysSleep

    # Screenshot the window using imagemagick
    if [ ! -d "${output}" ]; then
        mkdir "${output}"
    fi

    afterScreenshot="output/${host}.png"
    screenshot "${afterScreenshot}" "${window}"
    
    # Close the rdesktop window
    kill $pid

    # TODO OCR recognition
    # The method below isn't accurate enough
    if [ $(convert "${afterScreenshot}" -colors 5 -unique-colors txt:- | grep -c "#000000") -gt 0 ]; then
        echo -e "$green ${host} may have a backdoor"
    else
        echo -e "$blue ${host} may not have a backdoor"
    fi
fi
