# Report the DataMover.HardwareAcceleratedMove setting for all hosts.
# Hosts in not responding state will give an error.
Function Get-XCOPYSetting {
    $hostCollection = @() # Create a collection of all the ESXi hosts tested. 
    $VCName = $global:DefaultVIServer.name

    Write-Host "`nVAAI XCOPY setting check." -ForegroundColor Green
    Write-Host "DataMover.HardwareAcceleratedMove : "-ForegroundColor Green
    Write-Host "0 = disabled" -ForegroundColor Green
    Write-Host "1 = enabled" -ForegroundColor Green

    Write-Host "Due to issues documented below, we may want this to be 0." -ForegroundColor Green
    Write-Host "https://kb.vmware.com/s/article/74595 - possible VMFS corruption" -ForegroundColor Green
    Write-Host "https://kb.vmware.com/s/article/2146567 - how to disable" -ForegroundColor Green

    # Get the information for the ESXi hosts worksheet    
    $ESXiHosts = Get-VMHost 
    foreach ($ESXiHost in $ESXiHosts) {                
        if ($ESXiHost.IsStandalone) { $clusterName = 'Standalone' } else { $clusterName = $ESXiHost.Parent.Name }				
        $vaaiCheck = Get-AdvancedSetting -Entity $ESXiHost -Name DataMover.HardwareAcceleratedMove
                
        # Create our custom object with the properties we need for each ESXi host checked and add to our hostCollection
        $ESXiInfo = [PSCustomObject]@{
            vCenter                             = $vcName
            Cluster                             = $clusterName
            ESXiHost                            = $ESXiHost.Name
            "DataMover.HardwareAcceleratedMove" = $vaaiCheck.value
        }
        $hostCollection += $ESXiInfo  # Add this objection to our collection of ESXiHosts                   
    } # end foreach ($ESXiHost in $ESXiHosts)    

    # Display the results
    $hostCollection | Out-Host
} # end Get-XCOPYSetting
