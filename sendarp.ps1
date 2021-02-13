# sendarp.ps1

# Command-line parameters.
param(
    [parameter(mandatory)][IPAddress]$DestIP,
    [IPAddress]$SrcIP = "0.0.0.0"
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

# P/Invoke parameters.
$dst = [BitConverter]::ToUInt32($DestIP.GetAddressBytes(), 0)
$src = [BitConverter]::ToUInt32($SrcIP.GetAddressBytes(), 0)
$mac = New-Object byte[] 6
$len = [UInt32]$mac.Length

# Send ARP request.
$ret = [Win32ApiSendARP]::SendARP($dst, $src, $mac, [ref]$len)
if($ret -eq 0) {
    Write-Output "$DestIP is at $( ( $mac | ForEach-Object { "{0:x2}" -F $_ } ) -Join ":" )"
} else {
    Write-Output "Error while resolving $DestIP. Error code: $ret. See help: https://docs.microsoft.com/en-us/windows/win32/debug/system-error-codes"
}
