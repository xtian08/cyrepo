#!/bin/sh

# VyprVPN Re-Connection Script
# version: 0.4
# copyright: 22degrees
# date: 2018-01-28
# license: MIT


# Configuration
user="admin"
password="sampaguita"
ipaddress="192.168.2.1"
protocol="Chameleon"

# Set the location and hostname
# see https://support.goldenfrog.com/hc/en-us/articles/204088603-VyprVPN-OpenVPN-Setup-for-Tomato
# For countries with several server, add the city to the location e.g. "US - Washington" 
# You can extend or shorten the list, than change the quantity
location1="Philippines"
hostname1="ph1.vyprvpn.com"

quantity=1

# Get detailed information
# yes:1 no:0 default:0
debug=0

# Set time for hosts with no response
# default:999
noresponsetime=999

# Wait after boot or reconnect in seconds
# default:90
sleep 90


##### DO NOT EDIT AFTER THIS LINE #####

# Ping your favorite hosts
i=1; 
while [ $i -le $quantity ]; do
    eval hostname=\$hostname$i
    
    if [[ $debug -eq 1 ]]; then logger "Ping $hostname"; fi
    eval pingtime$i="$(ping -c 1 $hostname | sed '$!d;s|.*/\([0-9.]*\)..../.*|\1|')"
    
    eval noresponse=\$pingtime$i
    if [[ -z $noresponse ]]; then
        if [[ $debug -eq 1 ]]; then logger "no response: set time to $noresponsetime ms"; fi
        eval pingtime$i="$noresponsetime"
    fi

    i=$((i+1))
done


# Get the result of the ping test
if [[ $debug -eq 1 ]]; then
    i=1;
    while [ $i -le $quantity ]; do

        eval logger "Location: \$location$i Server: \$hostname$i Time: \$pingtime$i ms"

        i=$((i+1))
    done
fi


# Use first element as initial value for max/min;
eval maxpingtime=\$pingtime1
eval minpingtime=\$pingtime1

# Get the fastest and slowest connection
i=1;
while [ $i -le $quantity ]; do
    eval pingtime=\$pingtime$i

    if [[ "$pingtime" -ge "$maxpingtime" ]]; then
        maxpingtime="$pingtime"
        eval maxpingtimelocation=\$location$i
        eval maxpingtimehostname=\$hostname$i
    fi

    if [[ "$pingtime" -le "$minpingtime" ]]; then
        minpingtime="$pingtime"
        eval minpingtimelocation=\$location$i
        eval minpingtimehostname=\$hostname$i
    fi
    i=$((i+1))
done


# Output the fastest and slowest connection
if [[ $debug -eq 1 ]]; then
    logger "Fastest Connection: Location: $minpingtimelocation Server: $minpingtimehostname Time: $minpingtime ms"
    logger "Slowest Connection: Location: $maxpingtimelocation Server: $maxpingtimehostname Time: $maxpingtime ms"
fi


# Connect to the VyprVPN Network
if [[ ! -z "$minpingtimelocation" ]]; then
    logger "Connect to VyprVPN Location: $minpingtimelocation Server: $minpingtimehostname Time: $minpingtime ms"
    eval `wget "http://$user:$password@$ipaddress/user/cgi-bin/vyprvpn.cgi?[%22VYPRVPN_CONNECT%22,%22${minpingtimelocation// /%22}%22,%22$protocol%22]"`
fi
