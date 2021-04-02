Function Get-HostProcessorTypeCount {
    Write-Host "Breakdown of host processor types in the environment." -ForegroundColor Green
    Get-VMHost | Group-Object -Property @{Expression={$_.ProcessorType}} -NoElement | Sort-Object -Property Count | Format-Table -AutoSize
} # end Get-HostProcessorTypeCount
