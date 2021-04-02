# Wrapper to Get-ESXCli to retrieve vib list for host - 
Function Get-VIBList {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, Position = 1)]
        [string]$vmhost
    )
    $hostVIBList = (Get-ESXcli -V2 -VMHost $vmHost).software.vib.list.Invoke()
    Write-Host "`nList of VIBs installed on $vmHost : " -ForegroundColor Green -NoNewline
    $HostVIBList | Select-Object Name, ID, Version, Vendor, CreationDate, InstallDate, AcceptanceLevel | format-Table -autosize
} # end Get-VIBList
