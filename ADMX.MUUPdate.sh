#!/bin/bash

# Created by Chris Mariano (cdm436@nyu.edu)
# Description: MacOS Security Update Script via WS1 HubCLI
# License: MIT License
# Date: 2024-11-08
# Version: 6.0

# Define the path to the start date file read.me ws1muu
echo $(date)
start_date_file="/Users/shared/muufile.txt"
defer_days="3"
delay_days=0
CNlist=("name1" "ADUAEI15736LPMX" "name2") #Excluded for major

# Check if the start date file exists
if [ ! -f "$start_date_file" ]; then
    # If the file doesn't exist, create it and write the current date
    date +%s > "$start_date_file"
fi

# Read the start date from the file
start_date=$(cat "$start_date_file")

# Fetch the HTML content and extract version numbers and OS names
curl -s https://support.apple.com/en-ae/109033 | \
grep -o '<div class="table-wrapper gb-table">.*</div>' | \
awk -F'<tr>' '{for(i=2; i<=NF; i++) {gsub(/<\/?(p|th|td|tr)[^>]*>/,"",$i); if($i ~ /macOS/) print $i; else printf "%s\n", $i}}' | \
tee /tmp/apple_versions_and_names.txt | \
grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' > /tmp/apple_versions.txt

# Get the latest version and its corresponding OS name
latest_version=$(cat /tmp/apple_versions_and_names.txt | grep -Eo '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n 1)
latest_os_name=$(cat /tmp/apple_versions_and_names.txt | grep -Eo 'macOS [A-Za-z]+' | head -n 1)

# Extract the major version from the latest version (e.g., "15" from "15.1")
major_version=$(echo $latest_version | cut -d'.' -f1)

Current_OS="$latest_os_name $major_version"
echo "Current OS: $Current_OS"

# Fetch the HTML content from the target page
secURL="https://support.apple.com"
html_content=$(curl -s $secURL/en-ae/100100)
href=$(echo "$html_content" | \
grep -o "<a href=\"[^\"]*\" class=\"gb-anchor\">$Current_OS</a>" | \
sed -E 's/.*href="([^"]+)".*/\1/')

FullOSurl=$secURL$href
echo "Current OS URL: $FullOSurl"

# Fetch the release date from the FullOSurl page using sed
release_date=$(curl -s $FullOSurl | sed -n 's/.*<div class="note gb-note"><p class="gb-paragraph">Released \([^<]*\)<\/p><\/div>.*/\1/p')
echo "Release Date: $release_date"

# Convert the release date to Unix timestamp
release_timestamp=$(date -j -f "%B %d, %Y" "$release_date" +%s)

# Get the current date in Unix timestamp format
current_timestamp=$(date +%s)

# Calculate the difference in days
days_diff=$(( (current_timestamp - release_timestamp) / 86400 ))
echo "$days_diff days since release date"
if [ $days_diff -gt $delay_days ]; then ddb="Yes"; else ddb="NO"; fi
echo "Is the release date more than $delay_days days? $ddb"

# Get sw_vers -productVersion
mac_version=$(sw_vers -productVersion)
#mac_version="15.3" #Simulate other version
echo "Installed Version: $mac_version"

# Extract mac_major version
major_mac=$(echo "$mac_version" | cut -d '.' -f 1) 
minor_mac=$(echo "$mac_version" | cut -d '.' -f 2)
sub_minor_mac=$(echo "$mac_version" | cut -d '.' -f 3)
if [ -z "$sub_minor_mac" ]; then
    sub_minor_mac="0"  
fi

# Find the corresponding version in the list
version=$(grep "^$major_mac\." /tmp/apple_versions.txt)

# Check if version exists
if [ -n "$version" ]; then
    echo "CURRENT build for $major_mac is $version"
else
    echo "CURRENT build for $major_mac is not available"
fi

# Extract major version from the version
major=$(echo "$version" | cut -d '.' -f 1)
minor=$(echo "$version" | cut -d '.' -f 2)
sub_minor=$(echo "$version" | cut -d '.' -f 3)
if [ -z "$sub_minor" ]; then
    sub_minor="0"  
fi

# Fetch latest OS versions
os_list=$(softwareupdate --list-full-installers | awk -F 'Version: |, Size' '/Title:/{print $2}')

#Simulate other version


sorted_os_list=$(sort -r --version-sort <<<"$os_list")
sorted_os_list_n1=$(echo "$sorted_os_list" | grep -v '^'$major_version'')
hori_list=$(echo "$sorted_os_list" | tr '\n' ' ')
echo "List of available version $hori_list"
highest_version=$(echo "$sorted_os_list" | head -n 1)
ARCH=$(uname -m)
Cname=$(scutil --get ComputerName)
SNum=$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}')


# Extract highest_version version
major_now=$(echo "$highest_version" | cut -d '.' -f 1) 
minor_now=$(echo "$highest_version" | cut -d '.' -f 2)
sub_minor_now=$(echo "$highest_version" | cut -d '.' -f 3)
if [ -z "$sub_minor_now" ]; then
    sub_minor_now="0"  
fi
#Check if the release date is more than delay days ago

if [[ " ${CNlist[@]} " =~ " ${Cname} " ]]; then
    highest_version="$mac_version"
    echo "Device is excluded for major upgrade"
    echo "Highest version available1: $highest_version"
    #Checked OK - add CN exclusion
elif [ $major_version == $major_mac ]; then
    highest_version="$version"
    echo "Highest version available2: $highest_version"
    #Check OK
elif [ "$ddb" == "NO" ]; then
    highest_version=$(echo "$sorted_os_list_n1" | head -n 1)
    echo "Highest version available3: $highest_version"   
    #Check OK - default is NO
elif [ "$ARCH" == "arm64" ]; then
    echo "Highest version available4: $highest_version"
    #Check OK - default is arm64
elif [ $major_mac -ge $major_version ]; then
    echo "Highest version available5: $highest_version"
    #Check OK - default is -ge
else
    highest_version=""
    echo "Highest version not unavailable"
fi

# If SU result is empty, set static value
if [ -z "$highest_version" ]; then
    # Check if the release date is more than delay days ago
    if [ $days_diff -gt $delay_days ]; then
        echo "Allowed OS is $major (static)"
    elif [ $major_mac -lt $major_version ]; then
        echo "Allowed OS is $major (static)"
    else
        if [ $days_diff -gt $delay_days ]; then major=$((major - 0)); else major=$((major - 1)); fi
        echo "Allowed OS is $major"
    fi
    version=$(grep "^$major\." /tmp/apple_versions.txt)
    highest_version=$version
    echo "Highest version available: $highest_version"
fi

# Check if macOS version is less than 12.0
if (($major_mac < 12)); then
    # If macOS version is less than 12.0, mark as EOL
    echo "EOL"
    sudo rm "$start_date_file"
    exit 0
elif (($major_mac >= $major_now && $minor_mac >= $minor_now && sub_minor >= $sub_minor_now)); then
    # If macOS version is up to date, mark as Compliant
    echo "Compliant. No action required."
    sudo rm "$start_date_file"
    exit 0
else
    # If macOS version is outdated, notify user to upgrade
    current_date=$(date +%s)
    elapsed_days=$(( (current_date - start_date) / 86400 ))  # Calculate elapsed days
    remaining_days=$((defer_days - elapsed_days))  # Calculate remaining days

    if [ "$mac_version" == "$highest_version" ]; then
        echo "Compliant. No action required."
        sudo rm "$start_date_file"
        exit 0
    fi

    if [ $elapsed_days -ge $defer_days ]; then
        echo "Forced_Update to $highest_version"
        sudo /usr/local/bin/hubcli notify \
        -t "NYUAD Mandatory macOS Upgrade" \
        -s "$defer_days days deferral had elapsed." \
        -i "Update to "$highest_version" is being applied on your machines, it will restart automatically once completed. The installation will take up to 30-40 Min and will be notified for reboot." 
        sudo /usr/local/bin/hubcli mdmcommand --osupdate --productversion "$highest_version" --installaction InstallASAP
    else
        echo "Notify_Update to $highest_version"
        # Defer option notify
        sudo /usr/local/bin/hubcli notify \
        -t "NYUAD MACOS Update to $highest_version" \
        -s "" \
        -i "Update now to begin. Once installed, you will be notified to restart your computer. The restart may take up to 30 min. You have $remaining_days days remaining to defer this update." \
        -a "Start update now" \
        -b "sudo /usr/local/bin/hubcli mdmcommand --osupdate --productversion "$highest_version" --installaction InstallASAP" \
        -c "Do this later"
    fi
fi

# Clean up temporary files
rm /tmp/apple_versions.txt
rm /tmp/apple_versions_and_names.txt

