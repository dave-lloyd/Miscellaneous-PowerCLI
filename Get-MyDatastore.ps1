# Wrapper to Get-Datastore to round the figures and include percentage and provisioned space.
function Get-MyDatastore {
    $dataStores = Get-Datastore | Select-Object name, 
        @{n = "CapacityGB"; E = { [math]::round($_.CapacityGB) } }, 
        @{n = "FreeSpaceGB"; E = { [math]::round($_.FreeSpaceGB) } }, 
        @{n = "ProvisionedSpaceGB"; E = {[math]::round(($_.ExtensionData.Summary.Capacity - $_.ExtensionData.Summary.FreeSpace + $_.ExtensionData.Summary.Uncommitted)/1GB,0)} },
        @{N = "PercentFree%"; E = { [math]::round($_.FreeSpaceGB / $_.CapacityGB * 100) } },
        @{N = "NAA"; E = {$_.ExtensionData.Info.Vmfs.Extent[0].DiskName }}, State

    Write-Host "`nDatastore list : " -ForegroundColor Green -NoNewline
    $dataStores
    Write-Host "Take note if provisioned space > capacity - the datastore is overprovisioned." -ForegroundColor Green
} # Get-MyDatastore
