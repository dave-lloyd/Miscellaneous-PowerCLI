Function Get-VMMemoryCount {
    Write-Host "Count of number of VMs with configured memory. Count = number of VMs, name = MemoryGB property" -ForegroundColor Green
    Get-VM | Group-Object -Property @{Expression={$_.MemoryGB}} -NoElement | Sort-Object -Property Count | Format-Table -AutoSize
} # end Get-VMMemoryCount
