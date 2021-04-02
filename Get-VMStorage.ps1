# Retrieve VM storage info - OS, vDisk and Datastore - needs VMwareTools to be running for OS level
Function Get-VMStorage {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, Position = 1)]
        [string]$vm
    )

    $vmDetails = Get-VM $vm
    Write-Host "`nReport for $($vmDetails.name)" -ForegroundColor Green
    $OSUsage = $vmDetails.Guest.Disks | Select-Object Path, 
        @{n="Capacity (GB)"; E={[math]::round($_.CapacityGB)}}, 
        @{n="Free space (GB)"; E={[math]::round($_.FreeSpaceGB)}} 

    Write-Host "`nStorage usage returned by VM at OS level: " -ForegroundColor Green -NoNewline
    If ($OSUsage) {
        $OSUsage | Out-Host
    } else {
        Write-Host "`nNo OS level information available.`nIt's likely the VM is either powered off, or VMwareToos are not installed/running.`n"
    }

    Write-Host "VM Disk Information :" -ForegroundColor Green -NoNewline
    $VMDisks = $vmDetails | Get-HardDisk -PipelineVariable hd | Select-Object name, filename, storageformat, capacityGB,
        @{n = "SCSI ID"; E = {$ctrl = $hd.Parent.ExtensionData.Config.Hardware.Device | Where-Object {$_.key -eq $hd.ExtensionData.ControllerKey}
        "$($ctrl.BusNumber):$($_.ExtensionData.UnitNumber)" } }
    $VMDisks | Format-Table -Autosize

    Write-Host "Datastore Information :" -ForegroundColor Green -NoNewline
    $ds = $vmDetails | Get-Datastore | Select-Object Name,
        @{n = "naa"; E = {$_.ExtensionData.Info.vmfs.Extent[0].Diskname} },
        CapacityGB,
        @{n = "FreeSpaceGB"; E = {[math]::round($_.FreeSpaceGB)} } 
    $ds | Out-Host

    $rdms = $vmDetails | Get-HardDisk | Where-Object {$_.DiskType -like "Raw*"} | Select-Object @{n = "VM Name"; E = {$_.Parent} },
        Name, DiskType,
        @{n = "NAA"; E = {$_.ScsiCanonicalName} },
        @{n = "VML"; E = {$_.DeviceName} },
        Filename,
        CapacityGB

    If ($rdms) {
        Write-Host "RDM details :" -ForegroundColor Green -NoNewline
        $rdms | Out-Host
    }

} # end Get-VMStorage