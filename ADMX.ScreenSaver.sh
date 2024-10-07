#!/bin/bash
# Created by Chris Mariano GIT:xtian08

#Variables
SSVersion="SSaverVer-04102024-03"
photoloc="/Users/Shared/NYUAD"
repo="NYUAD-IT/nyuad"
folder="SSaver"
macOS14SS="https://raw.githubusercontent.com/xtian08/cyrepo/master/ADMX.SSCheck.sh"

scr_paths=(
    "/System/Library/Frameworks/ScreenSaver.framework/Resources/iLifeSlideshows.saver"
    "/System/Library/Frameworks/ScreenSaver.framework/PlugIns/iLifeSlideshows.appex"
    "/System/Library/ExtensionKit/Extensions/iLifeSlideshows.appex"
)

# Function to apply screensaver settings
apply_screensaver_settings() {
    local Cuser=$1
    sudo -u "$Cuser" defaults -currentHost write com.apple.ScreenSaverPhotoChooser CustomFolderDict -dict identifier "$photoloc" name "NYUAD"
    sudo -u "$Cuser" defaults -currentHost write com.apple.ScreenSaverPhotoChooser SelectedFolderPath "$photoloc"
    sudo -u "$Cuser" defaults -currentHost write com.apple.ScreenSaverPhotoChooser SelectedSource -int 4
    sudo -u "$Cuser" defaults -currentHost write com.apple.ScreenSaverPhotoChooser ShufflesPhotos -bool false
    sudo -u "$Cuser" defaults -currentHost write com.apple.ScreenSaver.iLifeSlideShows styleKey -string "Classic"
    sudo -u "$Cuser" defaults -currentHost write com.apple.screensaver CleanExit -bool true
    #sudo -u "$Cuser" defaults -currentHost write com.apple.screensaver idleTime -int 600
    sudo -u "$Cuser" defaults -currentHost write com.apple.screensaver showClock -bool true
    sudo -u "$Cuser" defaults -currentHost write com.apple.screensaver tokenRemovalAction -int 0
    sudo -u "$Cuser" defaults -currentHost write com.apple.screensaver moduleDict -dict-add moduleName "iLifeSlideshows"
    sudo -u "$Cuser" defaults -currentHost write com.apple.screensaver moduleDict -dict-add path "$scr_path"
    sudo -u "$Cuser" defaults -currentHost write com.apple.screensaver moduleDict -dict-add type -int 0
}

# Function to set iLifeSlideshows module if available
set_module_if_exists() {
    local user=$1
    for scr_path in "${scr_paths[@]}"; do
        if [ -d "$scr_path" ]; then
            #echo "$scr_path exists."
            sudo -u "$user" defaults write com.apple.screensaver moduleDict -dict moduleName -string "iLifeSlideshows" path -string "$scr_path" type -int 0
            break
        fi
    done
}

# Main
current_user=$(stat -f "%Su" /dev/console)
echo "Current user: $current_user"

# Remove old SS config
sudo -u "$current_user" defaults -currentHost delete com.apple.ScreenSaverPhotoChooser > /dev/null 2>&1
sudo -u "$current_user" defaults -currentHost delete com.apple.ScreenSaver.iLifeSlideShows > /dev/null 2>&1

# Check SS
sudo bash -c "$(curl -fsSL $macOS14SS)"

# Apply new SS config
apply_screensaver_settings "$current_user"
set_module_if_exists "$current_user"

# Refresh preferences daemon
killall -hup cfprefsd
#open -a ScreenSaverEngine

Echo "NYUAD ScreenSaver succesfully updated"
sudo touch "/Users/Shared/$SSVersion"

exit 0
