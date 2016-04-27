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
stickyKeysSleep=7
timeout=60
timeoutStep=2
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

function moveMouse {
    xdotool mousemove 0 0
    xdotool mousemove 100 100
}

function isAlive {
    pid=$1
    kill -0 $pid 2>/dev/null
    if [ $? -eq 1 ]; then
        echo -e "${red} Process died, failed to connect to ${host}"
        exit 1
    fi
}

function isTimedOut {
    t=$1
    if [ $t -ge $timeout ]; then
        echo -e "${red} Timed out connecting to ${host}"
        kill $!
        exit 1
    fi
}

export DISPLAY=:0
moveMouse

# Launch rdesktop in the background
echo -e "${blue} Initiating rdesktop connection to ${host}"
rdesktop -u "" -a 16 $host &
pid=$!

# Get window id
window=
timer=0
while true; do
    # Check to see if we timed out
    isTimedOut $(printf "%.0f" $timer)

    # Check to see if the process is still alive
    isAlive $pid
    window=$(xdotool search --name ${host})
    if [ ! "${window}" = "" ]; then
        echo -e "${blue} Got window id: ${window}"
        break
    fi
    timer=$(echo "$timer + 0.1" | bc)
    sleep 0.1
done

# Set our focus to the RDP window
echo -e "${blue} Setting window focus to ${window}"
xdotool windowfocus "${window}"

# If the screen is all black delay timeoutStep seconds
timer=0
while true; do

    # Make sure the process didn't die
    isAlive $pid

    isTimedOut $timer

    # Screenshot the window and if the only one color is returned (black), give it chance to finish loading
    screenshot "${temp}" "${window}"
    colors=$(convert "${temp}" -colors 5 -unique-colors txt:- | grep -v ImageMagick)
    if [ $(echo "${colors}" | wc -l) -eq 1 ]; then
        echo -e "${blue} Waiting on desktop to load"
        sleep $timeoutStep
    else
        # Many colors should mean we've got a colsole loaded
        break
    fi
    timer=$((timer + timeoutStep))
done
rm ${temp}

# Some systems seemed to need a bit more time to load before they accepted input
sleep 2

# Send Windows key + p to trigger displayswitch.exe
echo -e "${blue} Attempting to trigger displayswitch.exe backdoor"
xdotool key --window ${window} super+p

# Send Windows key + = to trigger magnifier.exe, also Windows Key + - to reverse magnify effect
echo -e "${blue} Attempting to trigger magnifier.exe backdoor"
xdotool key --window ${window} super+equal
xdotool key --window ${window} super+minus

# Send Windows key + Enter to trigger narrator.exe
echo -e "${blue} Attempting to trigger narrator.exe backdoor"
xdotool key --window ${window} super+Return

# Send Windows key + u to trigger utilman.exe
echo -e "${blue} Attempting to trigger utilman.exe backdoor"
xdotool key --window ${window} super+u

# Send shift key 5 times to trigger sethc.exe
echo -e "${blue} Attempting to trigger sethc.exe backdoor"
xdotool key --window ${window} shift shift shift shift shift

# Seems to be a delay if cmd.exe is set as the debugger this probably needs some tweaking
echo -e "${blue} Waiting ${stickyKeysSleep} seconds for the backdoors to trigger"
sleep $stickyKeysSleep

# Screenshot the window using imagemagick
if [ ! -d "${output}" ]; then
    mkdir "${output}"
fi

afterScreenshot="${output}/${host}.png"
screenshot "${afterScreenshot}" "${window}"

# Close the rdesktop window
kill $pid

# TODO OCR recognition
