Function Get-HostModel {
    Write-Host "Breakdown of the physical host model types." -ForegroundColor Green
    Get-VMHost | Group-Object -Property @{Expression={$_.Model}} -NoElement | Sort-Object -Property Count | Format-Table -AutoSize
} # end Get-HostModel
