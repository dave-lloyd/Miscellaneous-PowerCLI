# Retrieve IP(s) from a VM - needs VMwareTools to be running
Function Get-VMIP {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, Position = 1)]
        [string]$vm
    )
    Write-Host "`nIPs returned by VM : " -ForegroundColor Green 
    (Get-VM $vm).ExtensionData.guest.ipaddress
} # end Get-VMIP
