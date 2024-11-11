# Define the URLs and paths
$psexecUrl = "https://github.com/NYUAD-IT/nyrepo/raw/main/PsExec.exe"
$psexecPath = "C:\temp\psexec.exe"
$logFile = "C:\temp\winget_log.txt"

# Check if PsExec.exe is already present
if (-Not (Test-Path $psexecPath)) {
    # Create the directory if it doesn't exist
    if (-Not (Test-Path "C:\temp")) {
        New-Item -Path "C:\temp" -ItemType Directory
    }

    # Download PsExec.exe
    Invoke-WebRequest -Uri $psexecUrl -OutFile $psexecPath
}

# Find winget.exe
$wingetPath = Get-ChildItem -Path "C:\Program Files\" -Filter winget.exe -Recurse -ErrorAction SilentlyContinue -Force | Select-Object -First 1 -ExpandProperty FullName

if (-Not $wingetPath) {
    Write-Error "winget.exe not found."
    exit
}

# Define the command to run winget, properly handling paths with spaces
$wingetCommand = "`"$wingetPath`" install --id Microsoft.OpenSSH.Beta --silent --accept-package-agreements --accept-source-agreements -e"

# Run winget command as SYSTEM using PsExec and log the output
Start-Process -FilePath $psexecPath -ArgumentList "-i 1 -s cmd /c $wingetCommand > $logFile 2>&1" -Wait -NoNewWindow

# Output the process log file path
Write-Output "The process output has been logged to $logFile"

# Check for errors in the process log file
if (Test-Path $logFile) {
    $logContent = Get-Content -Path $logFile
    if ($logContent) {
        Write-Output "Log file content:"
        Write-Output $logContent
    } else {
        Write-Output "Log file is empty."
    }
} else {
    Write-Output "Log file not found."
}
