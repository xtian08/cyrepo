 # Define the main function to search and simulate/delete Mozilla Firefox entries
function Search_Clean_FF_reg {
    param (
        [bool]$simulateDelete = $true
    )
    
    # Define the paths to search within HKEY_USERS, HKEY_LOCAL_MACHINE, WOW6432Node, and WowAA32Node
    $hkeyUsersPath = "Registry::HKEY_USERS"
    $hkeyLocalMachineBasePath = "Registry::HKEY_LOCAL_MACHINE\Software"
    $mozillaFirefoxPath = "Mozilla\Firefox"
    $wow6432NodePath = "WOW6432Node"
    $wowAA32NodePath = "WowAA32Node"

    # Get all user SIDs
    $userSIDs = Get-ChildItem -Path $hkeyUsersPath

    # Define a function to search for old Mozilla Firefox registry entries in HKEY_USERS and its WOW6432Node and WowAA32Node
    function Search-MozillaEntriesInHKU {
        param (
            [string]$userSID,
            [string]$firefoxPath,
            [bool]$simulateDelete
        )
        
        $firefoxKeyPaths = @(
            "$userSID\Software\$firefoxPath",
            "$userSID\Software\$wow6432NodePath\$firefoxPath",
            "$userSID\Software\$wowAA32NodePath\$firefoxPath"
        )
        
        foreach ($firefoxKeyPath in $firefoxKeyPaths) {
            try {
                # Check if the Firefox key exists in HKEY_USERS
                if (Test-Path -Path "$hkeyUsersPath\$firefoxKeyPath") {
                    Write-Output "Mozilla Firefox entries found for user SID: $userSID at $firefoxKeyPath"
                    
                    # Get all subkeys and values under the Firefox key
                    $firefoxKey = Get-ChildItem -Path "$hkeyUsersPath\$firefoxKeyPath" -Recurse
                    foreach ($item in $firefoxKey) {
                        if ($simulateDelete) {
                            Write-Output "Simulation: Deleting $($item.PSPath)"
                        } else {
                            Remove-Item -Path $item.PSPath -Recurse -Force
                            Write-Output "Deleted $($item.PSPath)"
                        }
                    }
                }
            } catch {
                Write-Error "Error accessing registry path for user SID: $userSID at $firefoxKeyPath. $_"
            }
        }
    }

    # Define a function to search for old Mozilla Firefox registry entries in HKEY_LOCAL_MACHINE and its WOW6432Node and WowAA32Node
    function Search-MozillaEntriesInHKLM {
        param (
            [string]$basePath,
            [string]$firefoxPath,
            [string]$description,
            [bool]$simulateDelete
        )
        
        $fullPath = "$basePath\$firefoxPath"
        
        try {
            # Check if the Firefox key exists in the specified path
            if (Test-Path -Path $fullPath) {
                Write-Output "Mozilla Firefox entries found in $description"
                
                # Get all subkeys and values under the Firefox key
                $firefoxKey = Get-ChildItem -Path $fullPath -Recurse
                foreach ($item in $firefoxKey) {
                    if ($simulateDelete) {
                        Write-Output "Simulation: Deleting $($item.PSPath)"
                    } else {
                        Remove-Item -Path $item.PSPath -Recurse -Force
                        Write-Output "Deleted $($item.PSPath)"
                    }
                }
            }
        } catch {
            Write-Error "Error accessing registry path in $description. $_"
        }
    }

    # Simulate deletion of found Mozilla Firefox entries in HKEY_USERS and its WOW6432Node and WowAA32Node
    foreach ($userSID in $userSIDs) {
        Search-MozillaEntriesInHKU -userSID $userSID.PSChildName -firefoxPath $mozillaFirefoxPath -simulateDelete $simulateDelete
    }

    # Simulate deletion of found Mozilla Firefox entries in HKEY_LOCAL_MACHINE and its WOW6432Node and WowAA32Node
    $localMachinePaths = @(
        "$hkeyLocalMachineBasePath",
        "$hkeyLocalMachineBasePath\$wow6432NodePath",
        "$hkeyLocalMachineBasePath\$wowAA32NodePath"
    )

    foreach ($path in $localMachinePaths) {
        $description = $path.Replace("Registry::", "")
        Search-MozillaEntriesInHKLM -basePath $path -firefoxPath $mozillaFirefoxPath -description $description -simulateDelete $simulateDelete
    }
}

function check-FF {

    #Get Installed Firefox Version
    $firefoxPath86 = Get-ChildItem -Path "${env:ProgramFiles(x86)}\Mozilla Firefox\firefox.exe" -ErrorAction SilentlyContinue
    $firefoxPath64 = Get-ChildItem -Path "${env:ProgramFiles}\Mozilla Firefox\firefox.exe" -ErrorAction SilentlyContinue
    $firefoxPathARM = Get-ChildItem -Path "${env:ProgramFiles(ARM)}\Mozilla Firefox\firefox.exe" -ErrorAction SilentlyContinue
    
    $firefoxPath = $firefoxPath86, $firefoxPath64, $firefoxPathARM | Where-Object { $_ -ne $null } | Select-Object -First 1
    
    if ($firefoxPath) {
        Write-Host ""
        $firefoxVersion = (Get-Command $firefoxPath.FullName).FileVersionInfo.FileVersion
        $firefoxType = if ($firefoxPath -eq $firefoxPath86) { "x86" } elseif ($firefoxPath -eq $firefoxPath64) { "x64" } else { "ARM" }
        Write-Host "Firefox installed is based on $firefoxType"
        Write-Host "Installed Firefox Version: $firefoxVersion"
    }
    else {
        Write-Host ""
        Write-Host "Firefox not found. Exiting"
        break
    
    } 
} 

function install-FF {
    $progressPreference = 'silentlyContinue'
    #Get Firefox latest stable version
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $j = Invoke-RestMethod -Uri 'https://product-details.mozilla.org/1.0/firefox_versions.json'
    $stableversion = $j.LATEST_FIREFOX_VERSION
    Write-Host "Latest stable firefox: $stableversion"
    
    # Define the download URLs for x64 and ARM versions
    $firefoxURLx64 = "https://download.mozilla.org/?product=firefox-latest&os=win64&lang=en-US"
    $firefoxURLarm = "https://download.mozilla.org/?product=firefox-latest&os=win64-aarch64&lang=en-US"
    
    # Define the installation directory
    $installDir = "C:\Program Files\Mozilla Firefox"
    
    # Create a WebClient object
    $webClient = New-Object System.Net.WebClient
    
    # Download and install Firefox based on the architecture
    if ($architecture -like "*ARM*") {
        Write-Host "Installing ARM Firefox..."
        $webClient.DownloadFile($firefoxURLarm, "$env:TEMP\firefox-installer.exe")
        Start-Process -Wait -FilePath "$env:TEMP\firefox-installer.exe" -ArgumentList "/S"
    } else {
        Write-Host "Installing 64-bit Firefox..."
        $webClient.DownloadFile($firefoxURLx64, "$env:TEMP\firefox-installer.exe")
        Start-Process -Wait -FilePath "$env:TEMP\firefox-installer.exe" -ArgumentList "/S"
    }
    
    # Clean up the installer
    Remove-Item -Path "$env:TEMP\firefox-installer.exe" -Force
    
    Write-Host "Firefox installation completed."
    
}
    
function check-FF {

#Get Installed Firefox Version
$firefoxPath86 = Get-ChildItem -Path "${env:ProgramFiles(x86)}\Mozilla Firefox\firefox.exe" -ErrorAction SilentlyContinue
$firefoxPath64 = Get-ChildItem -Path "${env:ProgramFiles}\Mozilla Firefox\firefox.exe" -ErrorAction SilentlyContinue
$firefoxPathARM = Get-ChildItem -Path "${env:ProgramFiles(ARM)}\Mozilla Firefox\firefox.exe" -ErrorAction SilentlyContinue

$firefoxPath = $firefoxPath86, $firefoxPath64, $firefoxPathARM | Where-Object { $_ -ne $null } | Select-Object -First 1

if ($firefoxPath) {
    Write-Host ""
    $firefoxVersion = (Get-Command $firefoxPath.FullName).FileVersionInfo.FileVersion
    $firefoxType = if ($firefoxPath -eq $firefoxPath86) { "x86" } elseif ($firefoxPath -eq $firefoxPath64) { "x64" } else { "ARM" }
    Write-Host "Firefox installed is based on $firefoxType"
    Write-Host "Installed Firefox Version: $firefoxVersion"
    install-FF
}
else {
    Write-Host ""
    Write-Host "Firefox not found. Exiting"
} 
}
       
# Call the function with the desired simulation flag
Search_Clean_FF_reg -simulateDelete $false
check-FF

