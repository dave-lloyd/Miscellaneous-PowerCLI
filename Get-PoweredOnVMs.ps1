# List number of powered on VMs
Function Get-PoweredOnVMs {
    $vmList = Get-VM | Where-Object {$_.powerstate -eq "PoweredOn"} | Select-Object Name, Powerstate, MemoryGB, NumCPU, vmhost | format-Table -AutoSize

    Write-Host "`nThere are Powered $($vmList.count) on VMs in the environment." -ForegroundColor Green
    Write-Host "They are : " -ForegroundColor Green -NoNewline
    $vmList 
} # end Get-PoweredOnVMs
