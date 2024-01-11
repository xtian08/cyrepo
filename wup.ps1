# Check if PSWindowsUpdate module is installed
$moduleInstalled = Get-Module -Name PSWindowsUpdate -ListAvailable

# If not installed, install the module
if (-not $moduleInstalled) {
    echo "Installing module"
    Install-Module -Name PSWindowsUpdate -Force -AllowClobber
}

# Import the module
Import-Module PSWindowsUpdate

# Configure update settings
$UpdateSettings = @{
    AutoSelectUpdates = $true
    DownloadOnly = $false
    InstallUpdates = $true
    AcceptAll = $true
}

# Get the list of pending updates
$Updates = Get-WUList

# Filter updates by classification (Critical and Security)
$FilteredUpdates = Get-WindowsUpdate -Severity Critical

# Check if filtered updates are available
if ($FilteredUpdates.Count -eq 0) {
    echo "Device is up-to-date"
    Exit
}

# Install filtered updates
echo "Installing..."
Install-WUUpdates @UpdateSettings -Updates $FilteredUpdates

echo "Success. Reboot required"

# If a reboot is required, display a message
if (Get-WURebootStatus -eq 'RebootPending') {
    echo "Reboot required"
} else {
    echo "Dev update completed"
}
