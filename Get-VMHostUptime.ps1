function Get-VMHostUptime {
<#
    .Synopsis
        Report the boottime and uptime (in days) for all hosts in the environment
    .DESCRIPTION
        Report the boottime and uptime (in days) for all hosts in the environment.
        It's just the boottime attribute from Get-VMHost and calculated property for the uptime.
    .NOTES
    Author          : Dave Lloyd
    Version         : 0.1
#>

    $HostUptime = Get-VMHost | Select-Object Name, 
        @{N = "BootTime"; E = { $_.ExtensionData.Summary.Runtime.BootTime} },
        @{N = "Uptime"; E = { New-Timespan -Start $_.ExtensionData.Summary.Runtime.BootTime -End (Get-Date) | Select-Object -ExpandProperty Days } }

    Write-Host "`nHost boottime and uptime (in days) : " -ForegroundColor Green -NoNewline
    $HostUptime | Format-Table -autosize
}