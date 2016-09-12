# Sticky Keys Hunter

This POC bash script tests for sticky keys and utilman  backdoors. The script will connect to an RDP server, send both the sticky keys and utilman triggers and screenshot the result.

This script was written to prove a theory I had about detecting these backdoors in a blackbox fashion, and hasn't been updated since I wrote my blog post, [Hunting Sticky Keys Backdoors](http://zachgrace.com/2015/03/23/hunting-sticky-keys-backdoors.html). However,
[@DennisMald](https://twitter.com/DennisMald) and [@notmedic](https://twitter.com/notmedic) furthered this research and released the [Sticky Keys Slayer](https://github.com/linuz/Sticky-Keys-Slayer) tool at their DEF CON 24 presentation, [Sticky Keys To The Kingdom](http://www.slideshare.net/DennisMaldonado5/sticky-keys-to-the-kingdom). Check out their tool as it has many improvements over this POC script.

## How does it work?

1. Connects to RDP using rdesktop
2. Sends shift 5 times using xdotool to trigger sethc.exe backdoors
3. Sends Windows+u using xdotool to trigger utilman.exe backdoors
3. Takes screenshot
4. Kills RDP connection

## Prerequisites

1. Linux host running an X server
2. The following packages: xdotool imagemagick rdesktop bc
    3. Debian/Ubuntu/Kali install: `apt-get install xdotool imagemagick rdesktop bc`
3. Screen cannot be locked during this process or all of the screenshots will turn out black

## Usage

Scan a single host: `./stickyKeysHunter.sh 192.168.1.10`

Scan Multiple hosts: `for i in $(cat list.txt); do ./stickyKeysHunter.sh "${i}"; done`

## TODO

1. Automatically analyze screenshots with OCR or image processing to identify backdoors.
2. Speed up/multithread the tool.
