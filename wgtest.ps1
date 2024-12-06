$folders = @("C:\Temp", "C:\ProgramData\Airwatch\unifiedagent\logs")
$searchString = "psu"

foreach ($folder in $folders) {
    Get-ChildItem -Path $folder -Recurse -File -ErrorAction SilentlyContinue | 
    Where-Object { Select-String -Path $_.FullName -Pattern $searchString -Quiet } | 
    ForEach-Object { Remove-Item -Path $_.FullName -Force; Write-Host "Deleted: $($_.FullName)" }
}

######### Perform Apps Update #########
# Define the URLs and paths
$psexecUrl = "https://github.com/xtian08/ADrepo/raw/main/PsExec.exe"
$psexecPath = "C:\temp\psexec.exe"

# Ensure PsExec.exe is available
if (-Not (Test-Path $psexecPath)) {
    # Create the directory if it doesn't exist
    New-Item -Path "C:\temp" -ItemType Directory -Force

    # Download PsExec.exe
    Invoke-WebRequest -Uri $psexecUrl -OutFile $psexecPath
}

# Function to update apps using winget with debug logs
function Update-Apps {
    param(
        [int]$TimeoutMinutes = 30
    )

    # Log the start of the update
    Write-Output "************* Running Apps Updates (Timeout ${TimeoutMinutes} mins) *************"

    try {
        # Locate winget.exe
        Write-Debug "Locating winget.exe in WindowsApps folder..."
        $windowsAppsPath = "$env:ProgramFiles\WindowsApps"
        $wingetPath = Get-ChildItem -Path $windowsAppsPath -Filter winget.exe -Recurse -ErrorAction SilentlyContinue -Force |
                      Select-Object -First 1 -ExpandProperty FullName

        if ($wingetPath) {
            Write-Host "winget.exe found at: $wingetPath"
            Write-Debug "Preparing arguments for winget.exe..."

            # Define arguments for winget.exe
            $wingetArgs = @(
                "upgrade",
                "--accept-package-agreements",
                "--accept-source-agreements",
                "--all",
                "--include-unknown",
                "--force",
                "--disable-interactivity",
                "--verbose",
                "--silent"
            ) -join " "

            # Define log file path with timestamp
            Write-Debug "Setting up log file path..."
            $logFilePath = "C:\ProgramData\AirWatch\UnifiedAgent\Logs\ADWX_WingetJob_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

            # Build the command with proper quoting
            Write-Debug "Building winget command..."
            $wingetCommand = "`"$wingetPath`" $wingetArgs"
            $cmdCommand = "/accepteula -s cmd /c `"$wingetCommand`""

            # Start winget.exe via PsExec
            Write-Debug "Starting winget process using PsExec..."
            $process = Start-Process -FilePath $psexecPath -ArgumentList "$cmdCommand > $logFilePath 2>&1" -PassThru -NoNewWindow

            # Wait for completion or timeout
            $timeout = $TimeoutMinutes * 60
            Write-Debug "Waiting for process to exit or timeout ($TimeoutMinutes minutes)..."
            $process.WaitForExit($timeout * 1000)

            # Log handling
            if (Test-Path $logFilePath) {
                Write-Debug "Log file found. Reading content..."
                $logContent = Get-Content -Path $logFilePath
                Write-Host "Log File Content:`n$logContent"
            } else {
                Write-Host "Log file not found."
            }

            # Check if the process is still running
            if (!$process.HasExited) {
                Write-Host "winget.exe did not complete within the timeout. Terminating the process."
                Write-Debug "Terminating the winget process..."
                $process.Kill()
            } else {
                Write-Host "winget.exe completed successfully."
            }
        } else {
            Write-Host "winget.exe not found on the system."
            Write-Debug "winget.exe could not be located in the expected paths."
        }
    } catch {
        Write-Error "An error occurred during the update process: $_"
    }
}

# Run Update-Apps twice
Write-Debug "Running Update-Apps twice..."
1..2 | ForEach-Object { Update-Apps -TimeoutMinutes 30 }
