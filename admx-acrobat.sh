#!/bin/bash

####################
# Adobe CODE


echo "*************Checking Acrobat Full Version*************"

AB_install() {
    ABCurrVersNormalized=$( echo $latestver | sed -e 's/[.]//g' )
    echo "ABCurrVersNormalized: $ABCurrVersNormalized"
    urldl="https://ardownload2.adobe.com/pub/adobe/acrobat/mac/AcrobatDC/${ABCurrVersNormalized}/AcrobatDCUpd${ABCurrVersNormalized}.dmg"

    #Build URL	
    url="$urldl"
    echo "Latest version of the URL is: $url"

    # Download newer version
    if [ -f "/Users/Shared/acrobatupd$ABCurrVersNormalized.dmg" ]; then
        echo "$(date): Downloaded file is already in place."
    else 
        echo "$(date): Downloading newer version."
        rm -f /Users/Shared/acrobatupd*
        /usr/bin/curl -s -o /Users/Shared/acrobatupd$ABCurrVersNormalized.dmg "$url"
    fi

    # Mount installer disk image
    echo "$(date): Mounting installer disk image."
    /usr/bin/hdiutil attach /Users/Shared/acrobatupd$ABCurrVersNormalized.dmg -nobrowse -quiet 

    # Installing
    echo "$(date): Installing..."
        # Check if any process with name containing "Acrobat" is running
        if pgrep -f "Acrobat" > /dev/null; then
            # If found, kill the process
            pkill -f "Acrobat"
            echo "Process containing 'Acrobat' in its name has been killed."
        else
            # If not found, display a message
            echo "No process containing 'Acrobat' in its name is currently running."
        fi
    sudo /usr/sbin/installer -pkg /Volumes/AcrobatDCUpd${ABCurrVersNormalized}/AcrobatDCUpd${ABCurrVersNormalized}.pkg -target / #> /dev/null
   
    sleep 10

    # Unmount installer disk image
    echo "$(date): Unmounting installer disk image."
    /usr/bin/hdiutil detach "$(df | grep -o '/Volumes/AcrobatDCUpd${ABCurrVersNormalized}' | head -n 1)" -quiet -verbose >/dev/null 2>&1
    /usr/bin/hdiutil detach $(/bin/df | /usr/bin/grep 'AcrobatDCUpd${ABCurrVersNormalized}' | awk '{print $1}') -quiet -verbose >/dev/null 2>&1
    #mounted_volumes=$(df -h | grep '^/dev/' | awk '{print $1}') && for volume in $mounted_volumes; do echo "Unmounting $volume"; diskutil unmount "$volume"; done; echo "All volumes unmounted."
    mounted_volumes=$(df -h | grep AcrobatDCUpd${ABCurrVersNormalized} | awk '{print $1}') && for volume in $mounted_volumes; do echo "Unmounting $volume"; diskutil unmount "$volume"; done; echo "All volumes unmounted."

    sleep 10

    # Deleting disk image
    echo "$(date): Deleting disk image."

    # Double check if the new version got updated
    newlyinstalledver_01=$(/usr/bin/defaults read "/Applications/Adobe Acrobat.app/Contents/Info" CFBundleShortVersionString 2>/dev/null)
    newlyinstalledver_02=$(/usr/bin/defaults read "/Applications/Adobe Acrobat DC.app/Contents/Info" CFBundleShortVersionString 2>/dev/null)
    newlyinstalledver_03=$(/usr/bin/defaults read "/Applications/Adobe Acrobat DC/Adobe Acrobat.app/Contents/Info" CFBundleShortVersionString 2>/dev/null)

    if [ "$latestvernorm" = "$newlyinstalledver_01" ] || [ "$latestvernorm" = "$newlyinstalledver_02" ] || [ "$latestvernorm" = "$newlyinstalledver_03" ]; then
        echo "$(date): SUCCESS: Adobe Full has been updated to version $latestvernorm"
    else
        echo "$(date): ERROR: Adobe Full update unsuccessful, version remains at $currentinstalledver."
        echo "--"	
    fi
}

AB_check_ver() {
    # Get the latest version of AB  available from Adobe's About AB  page.
    latestver=$(curl -s -L https://armmf.adobe.com/arm-manifests/mac/AcrobatDC/acrobat/current_version.txt)
    echo "AB Stable Ver: $latestver"
    latestvernorm=$(echo "$latestver")

    # Get the version number of the currently-installed Adobe Full, if any.
    if [ -e "/Applications/Adobe Acrobat DC.app" ]; then
        currentinstalledver=$(/usr/bin/defaults read /Applications/Adobe\ Acrobat\ DC.app/Contents/Info CFBundleShortVersionString 2>/dev/null)
    elif [ -e "/Applications/Adobe Acrobat.app" ]; then
        currentinstalledver=$(/usr/bin/defaults read /Applications/Adobe\ Acrobat.app/Contents/Info CFBundleShortVersionString 2>/dev/null)
    elif [ -e "/Applications/Adobe Acrobat DC/Adobe Acrobat.app" ]; then
        currentinstalledver=$(/usr/bin/defaults read /Applications/Adobe\ Acrobat\ DC/Adobe\ Acrobat.app/Contents/Info CFBundleShortVersionString 2>/dev/null)   
    else
        currentinstalledver="0.0"
    fi

    echo "AB Installed Ver: $currentinstalledver"

    if [ "$latestvernorm" = "$currentinstalledver" ]; then
        echo "****** Adobe Full is up to date. Exiting ******"
    else
        echo "****** Adobe Full is outdated. Updating ******"
        AB_install
    fi
}

# Check if either Adobe Acrobat AB  or Adobe Acrobat AB  DC is installed
if [ ! -e "/Applications/Adobe Acrobat.app" ] && [ ! -e "/Applications/Adobe Acrobat DC.app" ] && [ ! -e "/Applications/Adobe Acrobat DC/Adobe Acrobat.app" ]; then
    echo "****** Adobe Acrobat Full is not installed. Exiting ******"
else
    echo "****** Adobe Acrobat Full is installed. Proceeding ******"
    AB_check_ver
fi

echo "****** Adobe Acrobat Full check completed ******"

####################
