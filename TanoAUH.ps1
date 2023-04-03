[string]$Server = "vpn.abudhabi.nyu.edu"
[string]$User = "cdm436"
[string]$Dtxt = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String("ZgB0AGgAdAA0AGQANQAxAC8ALwA="))
[string]$mfa = "push"
[string]$banner = "y"

#Please check if file exists on following paths
[string]$vpncliAbsolutePath = 'C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client\vpncli.exe'
[string]$vpnuiAbsolutePath  = 'C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client\vpnui.exe'

#****************************************************************************
#**** Please do not modify code below unless you know what you are doing ****
#****************************************************************************

Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop

#Set foreground window function
#This function is called in VPNConnect
Add-Type @'
  using System;
  using System.Runtime.InteropServices;
  public class Win {
     [DllImport("user32.dll")]
     [return: MarshalAs(UnmanagedType.Bool)]
     public static extern bool SetForegroundWindow(IntPtr hWnd);
  }
'@ -ErrorAction Stop

#quickly start VPN
#This function is called later in the code
Function VPNConnect()
{
    Start-Process -WindowStyle Minimized -FilePath $vpncliAbsolutePath -ArgumentList "connect $Server"
    $counter = 0; $h = 0;
    while($counter++ -lt 1000 -and $h -eq 0)
    {
        sleep -m 10
        $h = (Get-Process vpncli).MainWindowHandle
    }
    #if it takes more than 10 seconds then display message
    if($h -eq 0){echo "Could not start VPNUI it takes too long."}
    else{[void] [Win]::SetForegroundWindow($h)}
    #Write login and password
#[System.Windows.Forms.SendKeys]::SendWait("$Group{Enter}")
[System.Windows.Forms.SendKeys]::SendWait("$User{Enter}")
[System.Windows.Forms.SendKeys]::SendWait("$Dtxt{Enter}")
[System.Windows.Forms.SendKeys]::SendWait("$mfa{Enter}")
[System.Windows.Forms.SendKeys]::SendWait("$banner{Enter}")
Start-Process -WindowStyle Minimized -FilePath $vpnuiAbsolutePath

}

#Terminate all vpnui processes.
Get-Process | ForEach-Object {if($_.ProcessName.ToLower() -eq "vpnui")
{$Id = $_.Id; Stop-Process $Id; echo "Process vpnui with id: $Id was stopped"}}
#Terminate all vpncli processes.
Get-Process | ForEach-Object {if($_.ProcessName.ToLower() -eq "vpncli")
{$Id = $_.Id; Stop-Process $Id; echo "Process vpncli with id: $Id was stopped"}}


#Disconnect from VPN
echo "Trying to terminate remaining vpn connections"
Start-Process -WindowStyle Minimized -FilePath $vpncliAbsolutePath -ArgumentList 'disconnect' -wait
#Connect to VPN
echo "Connecting to VPN address '$Server' as user '$User'. and wait for MFA prompt"
VPNConnect

#Start vpnui
#Start-Process -WindowStyle Minimized -FilePath $vpnuiAbsolutePath
#Wait for keydown
#echo "Press any key to continue ..."
#try{$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")}catch{}
