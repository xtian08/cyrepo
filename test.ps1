# Define the URL for the Google Chrome release information
$chromeReleaseURL = "https://omahaproxy.appspot.com/all.json"

# Get the latest Chrome release information
$chromeReleases = Invoke-RestMethod -Uri $chromeReleaseURL

# Find the latest stable version of 64-bit Chrome
$latestStableVersion = ($chromeReleases | Where-Object { $_.os == "win" -and $_.arch == "x64" -and $_.channel == "stable" } | Sort-Object -Property version -Descending)[0].version

# Get the currently installed Chrome version
$installedVersion = (Get-ItemProperty "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Google Chrome").DisplayVersion
Write-host $installedVersion

# Check if the installed version matches the latest version
if ($installedVersion -ne $latestStableVersion) {
    # Define the URL for the Google Chrome MSI installer
    $chromeMsiURL = "https://dl.google.com/chrome/install/GoogleChromeStandaloneEnterprise64.msi"

    # Download and install the latest MSI
    $tempDir = [System.IO.Path]::GetTempPath()
    $msiPath = Join-Path -Path $tempDir -ChildPath "GoogleChromeStandaloneEnterprise64.msi"
    Invoke-WebRequest -Uri $chromeMsiURL -OutFile $msiPath
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $msiPath /qn" -Wait

    # Clean up the downloaded MSI
    Remove-Item -Path $msiPath -Force
} else {
    Write-Host "Google Chrome is already up to date (version $latestStableVersion)."
}
