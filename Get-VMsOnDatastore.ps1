# Given a VM, list all the other VMs using the same datastore. Handy perhaps if checking for potential
# impact before snapshots.
function Get-VMsOnDatastore {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, Position = 1)]
        [string]$vm
    )

    $DSSummary = Get-VM $vm | Get-Datastore | Select-Object name, 
        @{n = "CapacityGB"; E = { [math]::round($_.CapacityGB) } }, 
        @{n = "FreeSpaceGB"; E = { [math]::round($_.FreeSpaceGB) } }, 
        @{N = "PercentFree%"; E = { [math]::round($_.FreeSpaceGB / $_.CapacityGB * 100) } }

    $VMsOnDS = Get-Datastore  $DSSummary.name | get-vm | Select-Object name, powerstate, memoryGB, numCPU, 
        @{n = "ProvisionedSpaceGB"; E = { [math]::round($_.ProvisionedSpaceGB) } }

    Write-Host "`nDatastore : " -ForegroundColor Green -NoNewline
    $DSSummary | Out-Host
    Write-Host "VMs on datastore :" $dsSummary.name -ForegroundColor Green -NoNewline
    $VMsOnDS | Format-Table -Autosize | Out-Host

} # end Get-VMsOnDatastore
