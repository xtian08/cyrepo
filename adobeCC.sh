#!/bin/bash

echo "*************Checking Adobe Apps*************"

# Define URLs for internal and external sources based on architecture
ARCH=$(uname -m)
INTERNAL_DOMAIN="dcwap-v1352-cs.abudhabi.nyu.edu"
if [ "$ARCH" == "x86_64" ]; then
    INTERNAL_CC_URL="http://$INTERNAL_DOMAIN/agents/Adobe/MX-X64-MAN-CCX_en_US_MAC.pkg"
    #EXTERNAL_CC_URL="https://ccmdls.adobe.com/AdobeProducts/StandaloneBuilds/ACCC/ESD/6.3.0/207/osx10/ACCCx6_3_0_207.pkg"
    EXTERNAL_CC_URL="https://github.com/NYUAD-IT/nyrepo/raw/main/MX-X64-MAN-CCX_en_US_MAC.pkg"
    RUM_URL="https://deploymenttools.acp.adobeoobe.com/RUM/MacIntel/RemoteUpdateManager.dmg"
elif [ "$ARCH" == "arm64" ]; then
    INTERNAL_CC_URL="http://$INTERNAL_DOMAIN/agents/Adobe/MX-ARM-MAN-CCX_en_US_MACARM.pkg"
    #EXTERNAL_CC_URL="https://ccmdls.adobe.com/AdobeProducts/StandaloneBuilds/ACCC/ESD/6.3.0/207/macarm64/ACCCx6_3_0_207.pkg"
    EXTERNAL_CC_URL="https://github.com/NYUAD-IT/nyrepo/raw/main/MX-ARM-MAN-CCX_en_US_MACARM.pkg"
    RUM_URL="https://deploymenttools.acp.adobeoobe.com/RUM/AppleSilicon/RemoteUpdateManager.dmg"
else
    echo "Unsupported architecture: $ARCH"
fi

# Define cache directory
CACHE_DIR="/Users/Shared"

# Function to download file if it doesn't already exist
download_if_not_exists() {
    local url=$1
    local destination=$2

    if [ -f "$destination" ]; then
        echo "$destination already exists. Skipping download."
    else
        echo "Downloading $url to $destination..."
        curl -L -o "$destination" "$url"
    fi
}

# Function to install Creative Cloud
install_creative_cloud() {
    local cc_pkg="$CACHE_DIR/CreativeCloudInstaller.pkg"

    # Check connectivity to internal server
    if ping -c 1 $INTERNAL_DOMAIN &> /dev/null; then
        echo "Internal server reachable. Downloading from internal server..."
        download_if_not_exists "$INTERNAL_CC_URL" "$cc_pkg"
    else
        echo "Internal server not reachable. Downloading from Adobe servers..."
        download_if_not_exists "$EXTERNAL_CC_URL" "$cc_pkg"
    fi

    # Install the package
    sudo installer -pkg "$cc_pkg" -target /

    echo "Adobe Creative Cloud installed successfully."
}

# Check if Adobe Creative Cloud is installed
if [ ! -d "/Applications/Adobe Creative Cloud" ]; then
    install_creative_cloud
else
    echo "Adobe Creative Cloud is already installed."
fi

# Check if Remote Update Manager is already installed
if [ -x "/usr/local/bin/RemoteUpdateManager" ]; then
    echo "Remote Update Manager is already installed."
else
    local rum_dmg="$CACHE_DIR/RemoteUpdateManager.dmg"
    local mount_point="/Volumes/RemoteUpdateManager"

    # Download Remote Update Manager
    download_if_not_exists "$RUM_URL" "$rum_dmg"

    # Mount the DMG
    hdiutil attach "$rum_dmg" -mountpoint "$mount_point"

    # Install Remote Update Manager
    sudo cp "$mount_point/RemoteUpdateManager" /usr/local/bin/
    sudo chmod +x /usr/local/bin/RemoteUpdateManager

    # Unmount the DMG
    hdiutil detach "$mount_point"

    echo "Remote Update Manager installed successfully."
fi

# Run Remote Update Manager silently
sudo /usr/local/bin/RemoteUpdateManager --action=install > /dev/null 2>&1 &

# Path to the Adobe Creative Cloud Uninstaller
uninstaller_path="/Applications/Utilities/Adobe Creative Cloud/Utils/Creative Cloud Uninstaller.app/Contents/MacOS/Creative Cloud Uninstaller"

# Check if the uninstaller exists
if [ -f "$uninstaller_path" ]; then
    echo "Adobe Creative Cloud Uninstaller found. Executing..."
    #sudo "$uninstaller_path" -u
else
    echo "Adobe Creative Cloud Uninstaller not found."
fi

echo "*************Adobe apps check completed"*************"
