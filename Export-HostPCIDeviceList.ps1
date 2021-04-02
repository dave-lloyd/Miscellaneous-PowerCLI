Function Export-HostPCIDeviceList {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, Position = 1)]
        [string]$vmhost
    )
        (Get-VMHost -name $vmhost).ExtensionData.Hardware.PciDevice | Export-CSV -NoTypeInformation "$vmhost-PCIDevice.csv"
        Write-Host "File generated : $vmhost-PCIDeviceList.csv" -ForegroundColor Green
} # end Export-HostPCIDeviceList