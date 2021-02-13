# sendarp-list-ps7.ps1
#
# Requirement:
#   Powershell 7 (pwsh.exe, not a powershell.exe)
#

# Command-line parameters.
# TargetList is a text file that includes IP address of targets (One address per line).
param(
    [parameter(mandatory)][string]$TargetList,
    [IPAddress]$SrcIP = "0.0.0.0",
    $ThrottleLimit = 500
)

# P/Invoke methods.
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class Win32ApiSendARP
{
    [DllImport("iphlpapi.dll", ExactSpelling=true)]
    public static extern int SendARP(UInt32 DestIP, UInt32 SrcIP, byte[] MacAddr, ref UInt32 PhyAddrLen);
}
"@ -Language CSharp

# Send ARP request to each host in the list.
Get-Content $TargetList | ForEach-Object -Parallel {
    [IPAddress]$DestIP = $_
    [IPAddress]$SrcIP = $using:SrcIP
    $dst = [BitConverter]::ToUInt32($DestIP.GetAddressBytes(), 0)
    $src = [BitConverter]::ToUInt32($SrcIP.GetAddressBytes(), 0)
    $mac = New-Object byte[] 6
    $len = [UInt32]$mac.Length
    $ret = [Win32ApiSendARP]::SendARP($dst, $src, $mac, [ref]$len)
    if($ret -eq 0) {
        Write-Output "$DestIP is at $( ( $mac | ForEach-Object { "{0:x2}" -F $_ } ) -Join ":" )"
    } else {
        Write-Output "Error while resolving $DestIP. Error code: $ret. See help: https://docs.microsoft.com/en-us/windows/win32/debug/system-error-codes"
    }
} -AsJob -ThrottleLimit $ThrottleLimit | Wait-Job | Receive-Job
