function Check-VMList {
    <#
    .SYNOPSIS
        Checks if VMs exist within the vCenter.

    .DESCRIPTION
        Checks if the VMs supplied in a file, exist within the vCenter. Why? This is for those times when asked to check a list of VMs where there's no
        pattern or sequence. The script simply reads in the file and checks if there's a match in the vCenter. It is hopefully a bit quicker than trying
        to pattern match

    .PARAMETER File
        Specify the file with the list of VMs to check for

    .EXAMPLE
        Check-VMList -File vmlist.txt
        
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True)]
        [String]$file
    )
    $vmList = Get-Content $File

    foreach ($vm in $vmlist) {
        try {
            Get-VM $vm -ErrorAction stop | Out-Null
            Write-Host "VM $vm found" -ForegroundColor Green
        } catch {
            Write-Host "VM $vm not located" -ForegroundColor Red
        }
    }
} # end Check-VMList
