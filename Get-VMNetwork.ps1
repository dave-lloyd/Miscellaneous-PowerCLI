Function Get-VMNetwork {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, Position = 1)]
        [string]$vm
    )

    $vmDetails = Get-VM $vm
    $net = $vmDetails | Get-NetworkAdapter | Select-Object Name, Type, NetworkName, ConnectionState, MacAddress | Format-Table -AutoSize
    $pg = Get-VirtualPortgroup -vm $vm | Select-Object Name, VirtualSwitch, VLANID | Format-Table -AutoSize

    $VMIPs = Get-VM $vm | Select-Object @{n = "VM Name"; E = {$_.Name} },
        @{n = "IPs"; E = {$_.guest.ipaddress -join "`n"}},
        VMHost, @{n = "OS Type"; E = {$_.ExtensionData.summary.guest.GuestFullName}} | Format-List

    Write-Host "`nReport for $($vmDetails.name)" -ForegroundColor Green
    Write-Host "`nIP details returned by VM at OS level: " -ForegroundColor Green -NoNewline
    If ($VMIPs) {
        $VMIPs 
    } else {
        Write-Host "`nNo OS level IP information available.`nIt's likely the VM is either powered off, or VMwareToos are not installed/running.`n"
    }

    Write-Host "VM Network Adapter Information :" -ForegroundColor Green -NoNewline
    $net 

    Write-Host "Portgroup Information :" -ForegroundColor Green -NoNewline
    $pg

} # end Get-VMNetwork
