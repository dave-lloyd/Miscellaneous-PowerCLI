Function Get-HostHyperThreading {
    Write-Host "Breakdown of hyperthreading being enabled/disabled." -ForegroundColor Green
    Get-VMHost | Group-Object -Property @{Expression={$_.HyperThreadingActive}} -NoElement | Sort-Object -Property Count | Format-Table -AutoSize
} # end Get-HostHyperThreading
