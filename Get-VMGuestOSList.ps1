Function Get-VMGuestOSList {
    # Gather info
    $vmList = get-VM
    $vmCount = $vmList | Group-Object -Property @{Expression={$_.Guest.OSFullName}} -NoElement  | Sort-Object -Property Count | Format-Table -AutoSize
    $OSPerVM = $vmList | Select-Object Name, Powerstate, @{ Name = "OS Type"; Expression = {$_.ExtensionData.Summary.Guest.GuestFullName }}

    # Display info
    Write-Host "`n=====> Breakdown of Guest OS types - powered off VMs will not return an OS type. <======" -ForegroundColor Green
    $vMCount
    Write-Host "=====> OS per VM. <=====" -ForegroundColor Green
    $OSPerVM | Sort-Object -Property "OS Type" | Format-Table -Autosize
} # end Get-VMGuestOSList