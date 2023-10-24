
#Get Installed Version
$ChromeRegistryPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe'

if (Test-Path $ChromeRegistryPath) {
    $GCVersionInfo = (Get-Item (Get-ItemProperty $ChromeRegistryPath).'(Default)').VersionInfo
    $installedVersion = $GCVersionInfo.ProductVersion
    echo "Installed is $installedVersion"
} else {
    echo "Chrome is not Installed"
}

#Get Latest Version
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$j = Invoke-WebRequest 'https://omahaproxy.appspot.com/all.json' | ConvertFrom-Json
$stable = $j.versions | where-object { $_.channel -eq "stable" -and $_.os -eq "win64"}
$latestStableVersion = $stable.version
echo "Latest stable is $latestStableVersion"

#Install Chrome
$systemInfo = Get-WmiObject -Class Win32_ComputerSystem
$architecture = $systemInfo.SystemType

if ($architecture -like "*ARM*") {
    Write-Host "ARM architecture is supported yet."
} else {
    # Check if the installed version matches the latest version
    if ($installedVersion -ne $latestStableVersion) {
        # Define the URL for the Google Chrome MSI installer
        $chromeMsiURL = "https://dl.google.com/chrome/install/GoogleChromeStandaloneEnterprise64.msi"

        # Download and install the latest MSI
        $tempDir = [System.IO.Path]::GetTempPath()
        $msiPath = Join-Path -Path $tempDir -ChildPath "GoogleChromeStandaloneEnterprise64.msi"
        Invoke-WebRequest -Uri $chromeMsiURL -OutFile $msiPath
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $msiPath /qn" -Wait
        Write-Host "Installed version $latestStableVersion"

        # Clean up the downloaded MSI
        Remove-Item -Path $msiPath -Force
    } else {
        Write-Host "Google Chrome is already up to date (version $latestStableVersion)."
    }
}

