<#
Create a custom PowerShell Windows action
#>

#A1 Cloud Upgrade Script
#v1.4 Chris Mariano

#1.0 Basic Install
#1.1 Acquire data from Sftp
#1.2 Force scut and install
#1.3 Change installer to msi
#1.4 Add SaaS detection
#1.5 msi verbose log c:\temp\a1msi.log
#1.6 change detection via registry

Set-ExecutionPolicy -ExecutionPolicy Bypass -Force 

#Detect Saas presence

$a1name = Get-ItemPropertyValue -Path HKLM:\SOFTWARE\WOW6432Node\TrendMicro\PC-cillinNTCorp\CurrentVersion -Name "Server"
$A1Saas = "y5vpnu.manage.trendmicro.com"

If ($a1name -eq $A1Saas) {

Write-Host "***<<Already Installed - Terminating Script>>***"
Exit 0}
    else {
       Write-Host "***<<Saas not found - Proceeding Installation>>***"
    }


#PrimeSCP

Set-ExecutionPolicy -ExecutionPolicy Bypass -Force 
New-Item -ItemType "directory" -Path "C:\temp\a1"

$stageLD2  = "C:\temp\a1\WinSCP.zip"
$stageUrl2 = "https://onedrive.live.com/download?cid=526DD67E59DA5B20&resid=526DD67E59DA5B20%21509885&authkey=ALBPH3r_vyFVq3U"
(New-Object System.Net.WebClient).DownloadFile($stageUrl2, $stageLD2)
Set-Location "C:\temp\a1"
Expand-Archive -Path winscp.Zip -DestinationPath .\winscp

Import-Module -name "C:\temp\a1\winscp" -Verbose
    # Set credentials to a PSCredential Object.
    $User = "cdm436"
    $scpText = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String("UgBVAFQAYQBNAE8AVwBuAEsARAB2AGQAQgB3AHgA"))
    $PWord = ConvertTo-SecureString $scpText -AsPlainText -Force
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord
    # Create a WinSCP Session.
    $sessionOptions = New-WinSCPSessionOption -Hostname "sftp.abudhabi.nyu.edu" -Protocol Sftp -PortNumber 4410 -Credential $Credential -SshHostKeyFingerprint "ssh-ed25519 255 c1:64:69:dd:07:2a:8f:43:04:89:af:81:35:df:00:b5"
    $session = New-WinSCPSession -SessionOption $sessionOptions


#tests for the presence of file and if exists tests against known hash, if any tests fail download file
function DownloadBlob{
 
    $filename = $args[0]
    $filehash = $args[1]
    $fileurl = $args[2]
    $filepath = $args[3]
    
    $file = $filepath + $filename

    if (Test-Path $file) {
    if ((Get-FileHash -Algorithm MD5 $file).Hash -eq $filehash) {
        } else {
    Receive-WinSCPItem -WinSCPSession $session -Path $fileurl -Destination $file 
    }
        } else {
    Receive-WinSCPItem -WinSCPSession $session -Path $fileurl -Destination $file
}}


$temp = "c:\temp\a1\"


#download blob files

write-host "downloading...."
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    
DownloadBlob "scut_1.0.0.zip" "32F9D6A43D5DB120EB23D32D827E1656" "/upload/scut_1.0.0.zip" $temp
DownloadBlob "agent_cloud_x64.msi" "25BE51E9ABE7EBEA569FFB2063F4ED11" "/upload/BCagent_cloud_x64.msi" $temp
DownloadBlob "7za920.zip" "2FAC454A90AE96021F4FFC607D4C00F8" "/upload/7za920.zip" $temp
Expand-Archive .\7za920.zip -DestinationPath .\7za920
  	
Set-Location "C:\temp\a1"
$cmdpath = 'c:\windows\system32\cmd.exe /c '


#Force TMOS Cleanup

    $7ZipPath = "'C:\temp\a1\7za920\7za.exe'"
    $zipFile = "'C:\temp\a1\scut_1.0.0.zip'"
    $cutdest = "'C:\temp\a1\cut'"
    $Decoded = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String('dAByAGUAbgBkAA=='))
    $cutcommand = "& $7ZipPath e -o$cutdest -y -tzip -p$Decoded $zipFile"
    iex $cutcommand
    $cutcommand = "& 'C:\temp\a1\cut\scut.exe' -noinstall"
    iex $cutcommand
   

     
#Wait for Cut Process to complete
do{
    $Proc = Get-Process scut -ErrorAction SilentlyContinue
    Start-Sleep 1
}until($Proc -eq $Null)

#Install Apex one if needed
Start-Process "msiexec.exe" -ArgumentList "/i ""C:\temp\a1\agent_cloud_x64.msi"" /quiet /norestart /Lv c:\temp\a1msi.log" -NoNewWindow -PassThru

#clean installer
Remove-WinSCPSession -ForceAll
Stop-Process -Name WinSCP -Force
Set-Location "C:\"
Remove-Item -Recurse -Force -Path 'C:\temp\a1'
