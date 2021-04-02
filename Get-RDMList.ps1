# Basic list of RDMs
Function Get-RDMList {
    Get-VM | Get-HardDisk | Where-Object {$_.DiskType -like "Raw*"} | Select-Object @{n = "VM Name"; E = {$_.Parent} },
        Name, DiskType,
        @{n = "NAA"; E = {$_.ScsiCanonicalName} },
        @{n = "VML"; E = {$_.DeviceName} },
        Filename,
        CapacityGB
} # end Get-RDMList
