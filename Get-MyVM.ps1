# Get-VM but with selected properties only, and storage figures rounded to be more presentable.
Function Get-MyVM {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $False, Position = 1)]
        [string]$vm
    )

    If ($vm) {
        Write-Host "vCenter : " $Global:DefaultVIServer
        Get-VM $vm | Select-Object @{n = "VM Name"; E = {$_.Name} },
            Powerstate, MemoryGB, numCPU, CoresPerSocket,
            @{n = "ProvisionedSpaceGB"; E = { [math]::round($_.ProvisionedSpaceGB) } }, 
            @{n = "Host"; E = {$_.vmhost}}
    } else {
        Write-Host "vCenter : " $Global:DefaultVIServer
        Get-VM | Select-Object @{n = "VM Name"; E = {$_.Name} },
            Powerstate, MemoryGB, numCPU, CoresPerSocket,
            @{n = "ProvisionedSpaceGB"; E = { [math]::round($_.ProvisionedSpaceGB) } }, 
            @{n = "Host"; E = {$_.vmhost}}
    }
} # end Get-MyVM