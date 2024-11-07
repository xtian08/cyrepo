#!/bin/bash

# Created by Chris Mariano (cdm436@nyu.edu)
# Description: MacOS Security Update Script via WS1 HubCLI
# License: MIT License
# Date: 2024-08-15
# Version: 4.0


# Define the path to the start date file read.me ws1muu
echo $(date)
start_date_file="/Users/shared/muuNOV2024.txt"
defer_days="3"

# Check if the start date file exists
if [ ! -f "$start_date_file" ]; then
    # If the file doesn't exist, create it and write the current date
    date +%s > "$start_date_file"
fi

# Read the start date from the file
start_date=$(cat "$start_date_file")

# Fetch the HTML content and extract table
curl -s https://support.apple.com/en-ae/109033 | \
grep -o '<div class="table-wrapper gb-table">.*</div>' | \
awk -F'<tr>' '{
    for(i=2; i<=NF; i++) {
        gsub(/<\/?(p|th|td|tr)[^>]*>/,"",$i);
        printf "%s\n", $i
    }
}' | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' > apple_versions.txt

# Get sw_vers -productVersion
mac_version=$(sw_vers -productVersion)
echo "This Mac: $mac_version || "

# Extract mac_major version
major_mac=$(echo "$mac_version" | cut -d '.' -f 1) 
minor_mac=$(echo "$mac_version" | cut -d '.' -f 2)
sub_minor_mac=$(echo "$mac_version" | cut -d '.' -f 3)
if [ -z "$sub_minor_mac" ]; then
    sub_minor_mac="0"  
fi

# Find the corresponding version in the list
version=$(grep "^$major_mac\." apple_versions.txt)

# Check if version exists
if [ -n "$version" ]; then
    echo "Latest security build for $major_mac is $version || "
else
    echo "Latest security build for $major_mac is not available || "
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
sorted_os_list=$(sort -r --version-sort <<<"$os_list")
highest_version=$(echo "$sorted_os_list" | head -n 1)
echo "Highest version available now: $highest_version || "

if [ -z "$highest_version" ]; then
    echo "No OS updates available. Setting static value || "
    major="14"
    version=$(grep "^$major\." apple_versions.txt)
    highest_version=$version
    echo "Highest version available: $highest_version || "
fi

# Extract highest_version version
major_now=$(echo "$highest_version" | cut -d '.' -f 1) 
minor_now=$(echo "$highest_version" | cut -d '.' -f 2)
sub_minor_now=$(echo "$highest_version" | cut -d '.' -f 3)
if [ -z "$sub_minor_now" ]; then
    sub_minor_now="0"  
fi

# Check if macOS version is less than 12.0
if (($major_mac < 12)); then
    # If macOS version is less than 12.0, mark as EOL
    echo "EOL"
    exit 0
elif (($major_mac >= $major_now && $minor_mac >= $minor_now && sub_minor >= $sub_minor_now)); then
    # If macOS version is up to date, mark as Compliant
    echo "Compliant"
    exit 0
else
    # If macOS version is outdated, notify user to upgrade
    current_date=$(date +%s)
    elapsed_days=$(( (current_date - start_date) / 86400 ))  # Calculate elapsed days
    remaining_days=$((defer_days - elapsed_days))  # Calculate remaining days
    
    if [ $elapsed_days -ge $defer_days ]; then
        echo "Forced_Update to $highest_version"
        sudo /usr/local/bin/hubcli notify \
        -t "NYUAD Mandatory macOS Upgrade" \
        -s "$defer_days days deferral had elapsed." \
        -i "Update is being applied on your machines, it will restart automatically once completed. The installation will take up to 30-40 Min and will be notified for reboot." 
        sudo /usr/local/bin/hubcli mdmcommand --osupdate --productversion "$highest_version" --installaction InstallASAP
        exit 0
    else
        echo "Notify_Update to $highest_version"
        # Defer option notify
        sudo /usr/local/bin/hubcli notify \
        -t "NYUAD Mandatory MAC OS Upgrade" \
        -s "" \
        -i "Update now to begin. Once installed, you will be notified to restart your computer. The restart may take up to 30 min. You have $remaining_days days remaining to defer this update." \
        -a "Start update now" \
        -b "sudo /usr/local/bin/hubcli mdmcommand --osupdate --productversion "$highest_version" --installaction InstallASAP" \
        -c "Do this later"
    fi
fi

# Clean up temporary files
rm apple_versions.txt
