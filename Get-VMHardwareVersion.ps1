Function Get-VMHardwareVersion {
    <#
    .SYNOPSIS
        Report hardware version for given VM, VMs in a cluster or all VMs in the environment.

    .DESCRIPTION
        Simple wrapper function to report the hardware version for given VM, VMs in a cluster or all VMs in the environment.
        Optional parameters - if none is supplied, then ALL VMs in the environment will be targetted.
        You can then send the output to .csv for a simple audit, or, if ImportExcel is installed, to an .xlsx file.

    .PARAMETER Cluster
        Cluster to target if parameter supplied

    .PARAMETER VM
        VM to target if parameter supplied

    .EXAMPLE
        Get-VMHardwareVersion -Cluster ClusterA

    .EXAMPLE
        Get-VMHardwareVersion VM VM1

    .EXAMPLE
        Get-VMHardwareVersion 
        
    #>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $False)]
        [string] $Cluster,
        [Parameter(Mandatory = $False)]
        [string] $VM    
    )

    If ($Cluster) {
        Get-Cluster $Cluster | Get-VM | Select-Object name, @{name = "HardwareVersion"; expression = { $_.extensiondata.config.version } }
    } elseif ($vm) {
        Get-VM $vm | Select-Object name, @{name = "HardwareVersion"; expression = { $_.extensiondata.config.version } }
    } else {
        Get-VM | Select-Object name, @{name = "HardwareVersion"; expression = { $_.extensiondata.config.version } }
    }
}