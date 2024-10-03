#!/bin/bash
# Created by Chris Mariano GIT:xtian08

scr_paths=(
    "/System/Library/Frameworks/ScreenSaver.framework/Resources/iLifeSlideshows.saver"
    "/System/Library/Frameworks/ScreenSaver.framework/PlugIns/iLifeSlideshows.appex"
    "/System/Library/ExtensionKit/Extensions/iLifeSlideshows.appex"
)
photoloc="/Users/Shared/NYUAD"

# GitHub repository and folder
repo="NYUAD-IT/nyuad"
folder="SSaver"

# Create the target directory
mkdir -p "$photoloc"

# Fetch and download files
curl -s "https://api.github.com/repos/$repo/contents/$folder" | \
grep '"name":' | cut -d '"' -f 4 | while read -r file; do
  sudo curl -L -o "$photoloc/$file" "https://raw.githubusercontent.com/$repo/master/$folder/$file"
done

# Function to apply screensaver settings
apply_screensaver_settings() {
    local Cuser=$1
    sudo -u "$Cuser" defaults -currentHost write com.apple.ScreenSaverPhotoChooser CustomFolderDict -dict identifier "/Users/Shared/NYUAD" name "NYUAD"
    sudo -u "$Cuser" defaults -currentHost write com.apple.ScreenSaverPhotoChooser SelectedFolderPath "/Users/Shared/NYUAD"
    sudo -u "$Cuser" defaults -currentHost write com.apple.ScreenSaverPhotoChooser SelectedSource -int 4
    sudo -u "$Cuser" defaults -currentHost write com.apple.ScreenSaverPhotoChooser ShufflesPhotos -bool false
    sudo -u "$Cuser" defaults -currentHost write com.apple.ScreenSaver.iLifeSlideShows styleKey -string "Classic"
    sudo -u "$Cuser" defaults -currentHost write com.apple.screensaver CleanExit -bool true
    sudo -u "$Cuser" defaults -currentHost write com.apple.screensaver idleTime -int 300
    sudo -u "$Cuser" defaults -currentHost write com.apple.screensaver showClock -bool true
    sudo -u "$Cuser" defaults -currentHost write com.apple.screensaver tokenRemovalAction -int 0
    sudo -u "$Cuser" defaults -currentHost write com.apple.screensaver moduleDict -dict-add moduleName "iLifeSlideshows"
    sudo -u "$Cuser" defaults -currentHost write com.apple.screensaver moduleDict -dict-add path "/System/Library/ExtensionKit/Extensions/iLifeSlideshows.appex"
    sudo -u "$Cuser" defaults -currentHost write com.apple.screensaver moduleDict -dict-add type -int 0
}

# Function to set iLifeSlideshows module if available
set_module_if_exists() {
    local user=$1
    for scr_path in "${scr_paths[@]}"; do
        if [ -d "$scr_path" ]; then
            #echo "$scr_path exists."
            sudo -u "$user" defaults write com.apple.screensaver moduleDict -dict moduleName -string "iLifeSlideshows" path -string "/System/Library/ExtensionKit/Extensions/iLifeSlideshows.appex" type -int 0
            break
        fi
    done
}

# Main
current_user=$(stat -f "%Su" /dev/console)
echo "Current user: $current_user"

# Remove old SS config
sudo -u "$current_user" defaults -currentHost delete com.apple.ScreenSaverPhotoChooser
sudo -u "$current_user" defaults -currentHost delete com.apple.ScreenSaver.iLifeSlideShows

# Check SS
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/xtian08/cyrepo/master/ADMX.SSCheck.sh)"

# Apply new SS config
apply_screensaver_settings "$current_user"
set_module_if_exists "$current_user"

# Refresh preferences daemon
killall -hup cfprefsd
#open -a ScreenSaverEngine

Echo "NYUAD ScreenSaver succesfully updated"

exit 0
