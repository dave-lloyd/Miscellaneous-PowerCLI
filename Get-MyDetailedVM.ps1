# More detailed than default Get-VM, and with storage figures rounded for presentation
Function Get-MyDetailedVM {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $False, Position = 1)]
        [string]$vm
    )

    If ($vm) {
        $vmDetails = Get-VM $vm

        $VMReport = $vmDetails | Select-Object @{n = "VM Name"; E = {$_.Name} },
            @{n = "OS Name"; E = {$_.ExtensionData.guest.hostname }},
            Powerstate, MemoryGB, numCPU, CoresPerSocket,
            @{n = "ProvisionedSpaceGB"; E = { [math]::round($_.ProvisionedSpaceGB) } }, 
            @{n = "Memory Hot Add"; E = {$_.ExtensionData.Config.MemoryHotAddEnabled} },
            @{n = "CPU Hot Add"; E = {$_.ExtensionData.Config.CPUHotAddEnabled} },
            @{n = "Host"; E = {$_.vmhost}},
            @{n = "IPs"; E = {$_.guest.ipaddress -join "`n"}}

        $net = $vmDetails | Get-NetworkAdapter | Select-Object Name, Type, NetworkName, ConnectionState, MacAddress 
        $pg = Get-VirtualPortgroup -vm $vm | Select-Object Name, VirtualSwitch, VLANID 
    
        $VMIPs = $vmDetails | Select-Object @{n = "VM Name"; E = {$_.Name} },
            @{n = "IPs"; E = {$_.guest.ipaddress -join "`n"}},
            VMHost, @{n = "OS Type"; E = {$_.ExtensionData.summary.guest.GuestFullName}} 
    
        Write-Host "`nReport for $($vmDetails.name)" -ForegroundColor Green
        Write-Host "VM details : " -ForegroundColor Green -NoNewline
        $VMReport

        Write-Host "`nIP details returned by VM at OS level: " -ForegroundColor Green -NoNewline
        If ($VMIPs) {
            $VMIPs | Format-List
        } else {
            Write-Host "`nNo OS level IP information available.`nIt's likely the VM is either powered off, or VMwareToos are not installed/running.`n"
        }
    
        Write-Host "VM Network Adapter Information :" -ForegroundColor Green -NoNewline
        $net | Format-Table -AutoSize
    
        Write-Host "Portgroup Information :" -ForegroundColor Green -NoNewline
        $pg | Format-Table -AutoSize
    
        $OSUsage = $vmDetails.Guest.Disks | Select-Object Path, 
        @{n="Capacity (GB)"; E={[math]::round($_.CapacityGB)}}, 
        @{n="Free space (GB)"; E={[math]::round($_.FreeSpaceGB)}} 
    
        Write-Host "`nStorage usage returned by VM at OS level: " -ForegroundColor Green -NoNewline
        If ($OSUsage) {
            $OSUsage | Format-Table -AutoSize
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

            
    } else {
        Get-VM | Select-Object @{n = "VM Name"; E = {$_.Name} },
            @{n = "OS Name"; E = {$_.ExtensionData.guest.hostname }},
            Powerstate, MemoryGB, numCPU, CoresPerSocket,
            @{n = "ProvisionedSpaceGB"; E = { [math]::round($_.ProvisionedSpaceGB) } }, 
            @{n = "Memory Hot Add"; E = {$_.ExtensionData.Config.MemoryHotAddEnabled} },
            @{n = "CPU Hot Add"; E = {$_.ExtensionData.Config.CPUHotAddEnabled} },
            @{n = "Host"; E = {$_.vmhost}},
            @{n = "IPs"; E = {$_.guest.ipaddress -join "`n"}}
    }
} # end Get-MyDetailedVM

