Function Get-HostMaintenanceModeCheck {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $False, Position = 1)]
        [string]$vmhost
    )

    If (-not $vmhost) {
        $vmHost = "GetEmAll"
    }

    $hostlist = @()

    ForEach ($HostStatus in Get-VMHost $vmhost ) {
        # Build a list of hosts for evential use in the prefab.
        $hostlist += $HostStatus.name

        # Is the host actually standalone or part of a cluster. If it's standalone, well, all the VMs are going to need 
        # shutting down anyway.
        Write-Host "////////////////////////////////////////////////////////////////////////////////"

        Write-Host "`n***** Begin Host Review : $Hoststatus *****" 
        
        # Check if admission control is enabled for the cluster which may prevent the host entering maintenance mode.
        if ($HostStatus.IsStandalone) {
            $HAPassOrFailed = "Standalone host"
            $CheckFailed = $True
        }
        else {
            # Let's check the HA status
            $ClusterChecks = $HostStatus | Get-Cluster 
            If ($ClusterChecks.HAEnabled) {
                If ($ClusterChecks.HAAdmissionControlEnabled) {
                    $HAPassOrFailed = "HA enabled - Admission control enabled."
                }
                else {
                    $HAPassOrFailed = "Enabled"
                }
            }
            else {
                $HAPassOrFailed = "Disabled"
                $CheckFailed = $True
            }

            # And now check DRS
            If (!($ClusterChecks.DRSEnabled)) {
                $DRSPassOrFail = "Disabled."
                $CheckFailed = $True
            }
            else {
                # Now need to check what the automation level is - fully, partially or manual
                If ($ClusterChecks.DRSAutomationLevel -eq "FullyAutomated") {
                    $DRSPassOrFail = "Enabled - fully automated"
                }
                elseif ($ClusterChecks.DRSAutomationLevel -eq "PartiallyAutomated") {
                    $DRSPassOrFail = "Enabled - Partially automated."
                }
                elseif ($ClusterChecks.DRSAutomationLevel -eq "Manual") {
                     $DRSPassOrFail = "Enabled - Manual"
                }

                $DRSRuleCheck = Get-DRSRule -Cluster $ClusterChecks -VMHost $HostStatus -WarningAction SilentlyContinue
                If ($DRSRuleCheck) {
                    $DRSRulesPassOrFail = "Present"
                    $CheckFailed = $True
                }
                else {
                    $DRSRulesPassOrFail = "None"    
                }
    
            }

            # Now check memory allocation for the cluster, and how entering maintenance mode would impact that.
            # Total cluster memory
            $ClusterHostMemoryTotal = $ClusterChecks | get-vmhost | Select-Object memoryTotalGB
            $ClusMem = $ClusterHostMemoryTotal.memorytotalGB | measure-object -sum
            $THM = [Math]::Round($ClusMem.sum, 2)

            # Memory of host being checked
            $SingleHostMemory = [Math]::Round($HostStatus.memoryTotalGB, 2)

            # Total allocated memory for powerd on VMs - $TAMOn        
            $VMsOn = $ClusterChecks | get-vm | where-object { $_.powerstate -eq "Poweredon" }            
            $VMsOnTotal = $VMsOn.memoryGB | measure-object -sum
            $CVMT = [Math]::Round($VMsOnTotal.sum, 2)  

            # Calculate the current percentage allocation
            $percentageAllocation = [Math]::Round(($CVMT / $THM) * 100, 2)

            # Calculate cluster memory - single host memory, then as a percentage
            $ClusterHostMemoryWithSingleHostFailure = [Math]::Round(($THM - $SingleHostMemory), 2)
            $PercentageAllocationForHostFailure = [Math]::Round(($CVMT / $ClusterHostMemoryWithSingleHostFailure) * 100, 2)        

            If ($PercentageAllocationForHostFailure -gt 100) {
                $ClusterHostMemoryPrediction = "Allocated memory for cluster will exceed 100%"
                $CheckFailed = $True
            }
            else {
                $ClusterHostMemoryPrediction = "Allocated memory for cluster will be less than 100%"
            }
        }

        If ($HostStatus.ConnectionState -eq "Maintenance") {
            $CurrentConnectionState = "Maintenance mode"
        }
        ElseIf ($HostStatus.ConnectionState -ne "Connected") {
            $CurrentConnectionState = "Disconnected or not responding."
        }
        else {
            $CurrentConnectionState = "Connected"
        }

        # Check if any VMs are in orphaned, disconnected, inaccessible or invalid state
        $VMStatusCheck = $HostStatus | Get-VM | Where-Object { $_.ExtensionData.Runtime.ConnectionState -ne "connected" } | Select-Object Name, @{n = "ConnectionState"; E = { $_.ExtensionData.Runtime.ConnectionState } }  
        If ($VMStatusCheck) {
            #$VMStatusCheck | ft
            $CheckFailed = $True
            $VMState = "VMs in orphaned, disconnected, invalid or inaccessible state."
        }
        else {
            $VMState = "All connected"
            #Write-Host "VM Connection state : All VMs connected." -ForegroundColor Green
        }

        # Check if any VMs are on local or non shared storage
        # Local datastores would have the MultipleHostAccess property set to false
        $ds = Get-Datastore -VMHost $HostStatus | Get-View | Where-Object { $_.Summary.MultipleHostAccess -match 'false' }

        $VMsOnLocalStorage = Get-VMhost $HostStatus | get-datastore $ds.name | Get-VM
        If ($VMsOnLocalStorage.count -gt 0) {

            # Are they powered on?
            $PoweredOnVMsOnLocalStorage = $VMsOnLocalStorage | Where-Object { $_.Powerstate -eq "PoweredOn" }
            If ($PoweredOnVMsOnLocalStorage.count -gt 0) {
                #$PoweredOnVMsOnLocalStorage.name | ft -AutoSize | Out-Host
                $VMOnLocalStoragePassOrFail = "Yes"
                $CheckFailed = $True
            }

            $PoweredOffVMsOnLocalStorage = $VMsOnLocalStorage | Where-Object { $_.Powerstate -eq "PoweredOff" }
            If ($PoweredOffVMsOnLocalStorage.count -gt 0) {
                #$PoweredOffVMsOnLocalStorage.name | ft -AutoSize | Out-Host
                $VMOnLocalStoragePassOrFail = "Powered off VMs are on local storage."
            }
        }
        else {
            $VMOnLocalStoragePassOrFail = "None"
        }

        # Check if any VMs have an ISO/CD attached
        $VMsWithISOs = get-vmhost $HostStatus | Get-VM | Get-CDDrive | Select-Object @{n = "VM"; E = "Parent" }, IsoPath | Where-Object { $_.IsoPath -ne $null }

        If ($VMsWithISOs.count -gt 0) {
            #$VMsWithISOs.VM.name | ft -autosize
            $VMsWithISOPassOrFail = "Yes"
            $CheckFailed = $True
        }
        else {
            $VMsWithISOPassOrFail = "None"
        }

        # Check if any VMs have an RDM attached
        $RDMsPresent = Get-VMHost $HostStatus | Get-VM | Get-HardDisk | Where-Object { $_.DiskType -like "Raw*" }
        If ($RDMsPresent.count -gt 0) {
            #$RDMSPresent | Select Parent, DeviceName, ScsiCanonicalName, Disktype, Filename, Name
            $VMsWithRDMsPassOrFail = "Yes"
            $CheckFailed = $True
        }
        else {
            $VMsWithRDMsPassOrFail = "None"
        }

        #$VMsOnHost = $HostStatus | Get-VM | select Name, Powerstate

        # Create a PSCustomOBject which will hold the summary report for each host
        # Add each entry to the host_collection array. We'll then use the host_collection
        # array of PSCustomObjects in the actual prefab itself.
        $info = [PSCustomObject]@{
            "Host" = $HostStatus
            "Current build number" = $HostStatus.Build
            "Host connection state" = $CurrentConnectionState
            "HA enabled" = $HAPassOrFailed
            "DRS enabled" = $DRSPassOrFail
            "DRS host affinity rules" = $DRSRulesPassOrFail
            "Predicted cluster memory allocation with host down " = $ClusterHostMemoryPrediction
            "VMs on local storage" = $VMOnLocalStoragePassOrFail
            "VMs with ISOs attached" = $VMsWithISOPassOrFail
            "VMs with RDMs" = $VMsWithRDMsPassOrFail
            "VM state" = $VMState
        } # end $info = [PSCustomObject]@{

        $host_collection += $Info
        $host_collection | Out-Host
        Write-Host "`n***** Finished Host Review : $Hoststatus *****`n" 
    } # end ForEach ($HostStatus in Get-VMHost $vmhost)

} # end Get-HostMaintenanceModeCheck
