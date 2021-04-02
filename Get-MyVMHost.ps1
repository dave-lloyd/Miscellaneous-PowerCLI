Function Get-MyVMHost {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, Position = 1)]
        [string]$vmhost
    )

    $TP = "-30" # time period - 30 days

    # Gather host info that we can work with
    $ESXiHost = Get-VMHost $vmhost

    # Gather info about the (hopefully) connected datastores
    $TotalDatastores = $ESXiHost | Get-Datastore
    $ConnectedDatastores = $TotalDatastores | Where-Object {$_.State -eq "Available"} # hopefully this will be the same number as the total datastores ...

    # Gather info about the VMs on this host.
    $VMsPerHost = $ESXiHost | Get-VM
    $RunningVMs = $VMsPerHost | Where-Object {$_.powerstate -eq "PoweredOn"}
    $AllocatedCPUs = $RunningVMs | Measure-Object -Property numcpu -Sum | Select-Object -ExpandProperty sum

    if ($ESXiHost.IsStandalone) { $clusterName = 'Standalone' } else { $clusterName = $ESXiHost.Parent.Name }				

    # Work out some performance figures
    $hoststat = "" | Select-Object HostName, MemMax, MemAvg, MemMin, CPUMax, CPUAvg, CPUMin
    $statcpu = Get-Stat -Entity ($ESXiHost)-start (get-date).AddDays($TP) -Finish (Get-Date)-MaxSamples 10000 -stat cpu.usage.average
    $statmem = Get-Stat -Entity ($ESXiHost)-start (get-date).AddDays($TP) -Finish (Get-Date)-MaxSamples 10000 -stat mem.usage.average

    $cpu = $statcpu | Measure-Object -Property value -Average -Maximum -Minimum
    $mem = $statmem | Measure-Object -Property value -Average -Maximum -Minimum
    
    $hoststat.CPUMax = [math]::round($cpu.Maximum, 2)
    $hoststat.CPUAvg = [math]::round($cpu.Average, 2)
    $hoststat.CPUMin = [math]::round($cpu.Minimum, 2)
    $hoststat.MemMax = [math]::round($mem.Maximum, 2)
    $hoststat.MemAvg = [math]::round($mem.Average, 2)
    $hoststat.MemMin = [math]::round($mem.Minimum, 2)

    # Determine the host uptime and boot date
    $Uptime = $Esxihost | Select-Object @{N = "Uptime"; E = { New-Timespan -Start $_.ExtensionData.Summary.Runtime.BootTime -End (Get-Date) | Select-Object -ExpandProperty Days } }
    $hostUptime = $Uptime.uptime

    # Pop all the info into a custom object that we can then output.
    $ESXinfo = [PSCustomObject]@{
        Hypervisor             = $ESXiHost.Name
        Cluster                = $clusterName
        ConnectionState        = $ESXiHost.ConnectionState
        "Boot time"            = $ESXiHost.ExtensionData.Summary.Runtime.BootTime
        "Uptime (days)"        = $hostUptime
        Vendor                 = $ESXiHost.ExtensionData.Summary.Hardware.Vendor
        Model                  = $ESXiHost.ExtensionData.Summary.Hardware.Model
        Version                = $ESXiHost.Version
        Build                  = $ESXiHost.Build
        CpuModel               = $ESXiHost.ExtensionData.Summary.Hardware.CpuModel
        CpuSockets             = $ESXiHost.ExtensionData.Summary.Hardware.NumCpuPkgs
        CpuCores               = $ESXiHost.ExtensionData.Summary.Hardware.NumCpuCores
        CpuThreads             = $ESXiHost.ExtensionData.Summary.Hardware.NumCpuThreads
        "Allocated CPUs"       = $AllocatedCPUs
        "CPU Ratio"            = "$("{0:N2}" -f ($AllocatedCPUs/$ESXiHost.ExtensionData.Summary.Hardware.NumCpuThreads))" + " : 1"
        "Memory GB"            = [math]::round($ESXiHost.MemoryTotalGB)
        "Allocated memory GB"  = [math]::round($ESXiHost.MemoryUsageGB)
        "Total datastores"     = $TotalDatastores.Count
        "Connected Datastores" = $ConnectedDatastores.Count
        "Total VMs"            = $VMsPerHost.Count
        "Running VMs"          = $RunningVMs.Count
        "30 days Max CPU (%)"  = $hoststat.CPUMax
        "30 days Min CPU (%)"  = $hoststat.CPUMin
        "30 days Avg CPU (%)"  = $hoststat.CPUAvg
        "30 days Max Mem (%)"  = $hoststat.MemMax
        "30 days Min Mem (%)"  = $hoststat.MemMin
        "30 days Avg Mem (%)"  = $hoststat.MemAvg
    }     

    Write-Host "`nCollected host info : " -ForegroundColor Green
    $ESXinfo | Out-Host

    Write-Host "Please treat the min, max, avg values with caution, as they are just`ncalculations based on samples over 30 days.`n" -ForegroundColor Green
} # End Get-MyVMHost