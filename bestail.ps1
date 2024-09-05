# Function to get the latest log file and tail its content
function Get-LatestLogAndTail {
    # Define the log file location
    $logPath = "C:\Program Files (x86)\BigFix Enterprise\BES Client\__BESData\__Global\Logs\"
    
    # Get the latest log file
    $latestLog = Get-ChildItem -Path $logPath -Filter "*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    
    if ($latestLog) {
        # Display the last 10 lines (equivalent to tail)
        Get-Content -Path $latestLog.FullName -Tail 10
    } else {
        Write-Host "No log files found."
    }
}

# Run the function
Get-LatestLogAndTail
