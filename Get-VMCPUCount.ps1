Function Get-VMCPUCount {
    Write-Host "Count of number of VMs with configured CPU count. Count = number of VMs, name = numCPU property" -ForegroundColor Green
    Get-VM | Group-Object -Property @{Expression={$_.NumCPU}} -NoElement | Sort-Object -Property Count | Format-Table -AutoSize
} # end Get-VMCPUCount
