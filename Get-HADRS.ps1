# Summary of cluster HA and DRS 
Function Get-HADRS {
    $Header = "`nCluster HA and DRS summary" 
    $Header = "$Header`n$('-' * $Header.length)"
    $Header

    Write-Host "`nCluster(s) HA configuration" -ForegroundColor Green
    Get-Cluster | Select-Object Name,
        HAEnabled,
        HAAdmissionControlEnabled,
        HAFailoverLevel,
        HARestartPriority,
        HAIsolationResponse | Format-Table -AutoSize

    Write-Host "`nCluster(s) DRS configuration" -ForegroundColor Green
    Get-Cluster | Select-Object Name,
        DrsEnabled,
        DrsMode,
        DrsAutomationLevel,
        @{n = "DRS Level"; E = {$_.ExtensionData.Configuration.DRSConfig.vMotionRate} },
        @{n = "Number of vMotions"; E = {$_.ExtensionData.Summary.numvmotions} } | Format-Table -AutoSize
} # end Get-HADRS
