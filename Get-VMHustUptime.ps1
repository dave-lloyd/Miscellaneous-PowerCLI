# Get the host boot time, and derive the uptime from this.
function Get-VMHostUptime {
    $HostUptime = Get-VMHost | Select-Object Name, 
    @{N = "BootTime"; E = { $_.ExtensionData.Summary.Runtime.BootTime} },
    @{N = "Uptime"; E = { New-Timespan -Start $_.ExtensionData.Summary.Runtime.BootTime -End (Get-Date) | Select-Object -ExpandProperty Days } }
    Write-Host "`nHost uptime (in days) : " -ForegroundColor Green -NoNewline
    $HostUptime | Format-Table -autosize
} # Get-VMHustUptime
