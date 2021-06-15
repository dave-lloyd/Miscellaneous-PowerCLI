Function Get-CDPInfo {
    # Based on https://kb.vmware.com/s/article/1007069
    $date = Get-Date -Format "yyyy-MMM-dd-HHmm"
    $vCenter = $global:DefaultVIServer.name
    # $CDPReportLog = "$vCenter-CDP-Report-" + $date + ".csv"
    $CDPReportLog_xlsx = "$vCenter-CDP-Report-" + $date + ".xlsx"
     
    Write-Host "`nGenerating report. This may take a few minutes depending on the size of the environment." -ForegroundColor Magenta
    $objReport = @()
    Get-VMHost | ForEach-Object { Get-View $_.ID } |
        ForEach-Object { $esxname = $_.Name; Get-View $_.ConfigManager.NetworkSystem } |
        ForEach-Object { foreach ($physnic in $_.NetworkInfo.Pnic) {

            $obj = "" | Select-Object Hostname, VMNIC, Speed, PCI, Port, NetworkSwitch, CDP_Address, VLAN, SwitchType 

            If ($_.connectionstate -eq "Not Responding") {
                $obj.Port = "Host nay responding lad"   
                $objReport += $obj
            } else {
            
                $pnicInfo = $_.QueryNetworkHint($physnic.Device) 
                foreach ($hint in $pnicInfo) {
                    $obj.Hostname = $esxname
                    $obj.VMNIC = $physnic.Device
                    $obj.Speed = $physnic.LinkSpeed.SpeedMb
                    $obj.PCI = $physnic.PCI
                    if ( $hint.ConnectedSwitchPort ) {
                        $obj.Port = $hint.ConnectedSwitchPort.PortId
                    }
                    else {
                        $obj.Port = "No CDP information available."
                    }
                    $obj.NetworkSwitch = $hint.ConnectedSwitchPort.DevId
                    $obj.CDP_Address = $hint.ConnectedSwitchPort.Address
                    $obj.VLAN = $hint.ConnectedSwitchPort.VLAN
                    $obj.SwitchType = $hint.ConnectedSwitchPort.HardwarePlatform
                }

                $objReport += $obj
            }
    }

    # $objReport | Export-CSV -NoTypeInformation -Path $CDPReportLog
    #Write-Host "`nCSV report generated and available as $CDPReportLog" -ForegroundColor Green  

    $objReport | Export-Excel $CDPReportLog_xlsx -BoldTopRow -AutoFilter -FreezeTopRow -WorkSheetname CDP -AutoSize 
    Write-Host "`nExcel report generated and available as $CDPReportLog_xlsx" -ForegroundColor Green  

    Write-Host "`nDisconnecting from vCenter" -ForegroundColor Green
    Disconnect-VIServer -Server * -Force -Confirm:$false
        }
} # end Get-CDPInfo