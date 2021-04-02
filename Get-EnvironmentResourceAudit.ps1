Function Get-EnvironmentResourceAudit {
    $clus = get-cluster
    foreach ($clu in $clus) {        
        # Clear some of the variables
        $SingleHostMemory = 0      
        $ClusterHostMemoryWithSingleHostFailure = 0
        $PercentageAllocationForHostFailure = 0
  
        $vmh = get-cluster $clu | get-vmhost
        Write-Host
        $ClusterSelection = $($clu.name)
        ##
        # Collect data and process
        # Round the memory value to 2 decimal places.
        # Inelegant way of rounding the figures off - probably a better and more correct way should be looked for.
        $TempVMs = get-cluster $ClusterSelection | get-vm
        $VMsOff = $TempVMs | Where-Object { $_.powerstate -eq "PoweredOff" }
        $VMsOn = $TempVMs | Where-Object { $_.powerstate -eq "PoweredOn" }
                     
        # Total allocated memory for powerd on VMs - $TAMOn        
        $VMsOnTotal = $VMsOn.memoryGB | measure-object -sum
        $TAMOn = [Math]::Round($VMsonTotal.sum)
                          
        # Total allocated memory for powerd off VMs - $TAMOff      
        $VMsOffTotal = $VMsOff.memoryGB | measure-object -sum
        $TAMOff = [Math]::Round($VMsoffTotal.sum)
                         
        $ClusterVMMemTotal = $VMsOnTotal.sum + $VMsOffTotal.sum
        $CVMT = [Math]::Round($ClusterVMMemTotal)  
                          
        $ClusterHostMemoryTotal = get-cluster $ClusterSelection | get-vmhost | Select-Object memoryTotalGB
                         
        $ClusMem = $ClusterHostMemoryTotal.memorytotalGB | measure-object -sum
        $THM = [Math]::Round($ClusMem.sum)
                         
        # Calculate the current % allocation for ALL VMs - $CVMT / $ClusterHostMemoryTotal * 100
        $percentageAllocation = [Math]::Round(($CVMT / $THM) * 100)

        # Calculate the current % allocation for Powered ON VMs - $TAMOn / $ClusterHostMemoryTotal * 100
        $percentageAllocationON = [Math]::Round(($TAMON / $THM) * 100)
      
        # Calculate if we can run 100% workload on all remaining hosts in the event of a host failure.
        # Rather crude
        #$HostsMinusOne = ($NumHost.count - 1)
        $SingleHostMemory = [Math]::Round($vmh[0].memoryTotalGB)
        $ClusterHostMemoryWithSingleHostFailure = [Math]::Round(($THM - $SingleHostMemory))
        $PercentageAllocationForHostFailure = [Math]::Round(($CVMT / $ClusterHostMemoryWithSingleHostFailure) * 100)
        $PercentageAllocationForHostFailureONVMs = [Math]::Round(($TAMON / $ClusterHostMemoryWithSingleHostFailure) * 100)
 
        # Report output       
        Write-Host "`n----- Begin report on cluster $ClusterSelection -----"  -foregroundColor Yellow
        Write-Host "`nCluster Memory report." -ForegroundColor Green
        Write-Host "-----------------------" -ForegroundColor Green
        Write-Host "Total hosts                                                     :"$vmh.count -ForegroundColor Green
        Write-Host "Total Cluster memory                                            :"$THM"GB" -ForegroundColor Green
        Write-Host "Total Cluster memory if host fails/is in maintenance mode       :"$ClusterHostMemoryWithSingleHostFailure"GB" -ForegroundColor Green
       
        Write-Host "`nMemory allocated to VMs summary" -ForegroundColor Green
        Write-Host "-------------------------------" -ForegroundColor Green
        Write-Host "Powered ON VMs                                                  :"$VMsOn.count -foregroundcolor Green
        Write-Host "Allocated memory (GB)                                           :"$TAMOn"GB" -foregroundcolor Green                                
        Write-Host "`nPowered OFF VMs                                                 :"$VMsOff.count -foregroundcolor Green
        Write-Host "Allocated memory (GB)                                           :"$TAMOff"GB" -foregroundColor Green
        Write-host "`nAllocated memory (GB) for ALL VMs                               :"$CVMT"GB" -foregroundColor Green

        Write-Host "`nCluster percentage allocation and predicted allocation." -ForegroundColor Green
        Write-Host "--------------------------------------------------------" -ForegroundColor Green
        If ($percentageAllocation -ge 100) {
            Write-host "Cluster % allocation for ALL VMs                                :"$percentageAllocation "%" -foregroundColor Red
        } else {
            Write-host "Cluster % allocation for ALL VMs                                :"$percentageAllocation "%" -foregroundColor Green
        }
        If ($percentageAllocationON -ge 100) {        
            Write-host "Cluster % allocation for powered ON VMs                         :"$percentageAllocationON "%" -foregroundColor Red
        } else {
            Write-host "Cluster % allocation for powered ON VMs                         :"$percentageAllocationON "%" -foregroundColor Green
        }

        If ($PercentageAllocationForHostFailure -ge 100) {
            Write-Host "`nPredicted cluster % allocation if 1 host down ALL VMs           :"$PercentageAllocationForHostFailure "%" -ForegroundColor Red
        } else {
            Write-Host "`nPredicted cluster % allocation if 1 host down ALL VMs           :"$PercentageAllocationForHostFailure "%" -ForegroundColor Green
        }

        If ($PercentageAllocationForHostFailureONVMs -ge 100) {
            Write-Host "Predicted cluster % allocation if 1 host down Powered ON VMs    :"$PercentageAllocationForHostFailureONVMs "%" -ForegroundColor Red
        } else {
            Write-Host "Predicted cluster % allocation if 1 host down Powered ON VMs    :"$PercentageAllocationForHostFailureONVMs "%" -ForegroundColor Green
        }

        ## CPU Section
        Write-Host "`nCluster CPU report." -ForegroundColor Green
        Write-Host "--------------------" -ForegroundColor Green -NoNewline
        $vmhosts = get-cluster $clu | Get-VMHost
        $vms = Get-VM

        $Output = @()

        ForEach ($vmhost in $vmhosts) {
            $vcpus = 0
            $ratio = $null
            $hostthreads = $vmhost.extensiondata.hardware.cpuinfo.numcputhreads
            $vms | Where-Object { $_.vmhost -like $vmhost } | ForEach { $vcpus += $_.numcpu }
            if ($vcpus -ne "0") { $ratio = "$("{0:N2}" -f ($vcpus/$hostthreads))" + ":1" }

            $temp = New-Object psobject
            $temp | Add-Member -MemberType Noteproperty "Hostname" -value $vmhost.name
            $temp | Add-Member -MemberType Noteproperty "PhysicalThreads" -Value $Hostthreads
            $temp | Add-Member -MemberType Noteproperty "vCPUs" -Value $vcpus
            $temp | Add-Member -MemberType Noteproperty "Ratio" -Value $ratio
            $Output += $temp

        }
        $Output | Out-Host

        # Performance
        $TP = "-30"
        $allESXiHosts = Get-VMHost -Location $clu
        Write-Host "Host memory and CPU average, maximum and minimum for last 30 days." -ForegroundColor Green
        Write-Host "------------------------------------------------------------------" -ForegroundColor Green -NoNewline
    
        foreach ($ESXiHost in $allESXiHosts) {  
                                            
            $hoststat = "" | Select-Object HostName, MemMax, MemAvg, MemMin, CPUMax, CPUAvg, CPUMin
            $statcpu = Get-Stat -Entity ($ESXiHost)-start (get-date).AddDays($TP) -Finish (Get-Date)-MaxSamples 10000 -stat cpu.usage.average
            $statmem = Get-Stat -Entity ($ESXiHost)-start (get-date).AddDays($TP) -Finish (Get-Date)-MaxSamples 10000 -stat mem.usage.average
        
            $cpu = $statcpu | Measure-Object -Property value -Average -Maximum -Minimum
            $mem = $statmem | Measure-Object -Property value -Average -Maximum -Minimum
                        
            $hoststat.CPUMax = [math]::round($cpu.Maximum, 2)
            $hoststat.CPUAvg = [math]::round($cpu.Average, 2)
            $hoststat.CPUMin = [math]::round($cpu.Minimum, 2)
            $hoststat.MemMax = [math]::round($mem.Maximum, 2)
            $hoststat.MemAvg = [math]::round($mem.Average, 2)
            $hoststat.MemMin = [math]::round($mem.Minimum, 2)
    
            Write-Host "`nHost : $ESXIHost" -ForegroundColor Green
            Write-Host "30 days Max CPU :" $hoststat.CPUMax "%" -ForegroundColor Green
            Write-Host "30 days Min CPU :" $hoststat.CPUMin "%" -ForegroundColor Green
            Write-Host "30 days Avg CPU :" $hoststat.CPUAvg "%" -ForegroundColor Green
            Write-Host "30 days Max Mem :" $hoststat.MemMax "%" -ForegroundColor Green
            Write-Host "30 days Min Mem :" $hoststat.MemMin "%" -ForegroundColor Green
            Write-Host "30 days Avg Mem :" $hoststat.MemAvg "%" -ForegroundColor Green    
        }
            Write-Host "`nNote that these figures should not be taken as a definitive statement on performance." -ForegroundColor Green
            Write-Host "They are based on 10000 stats over 30 days, and the granularity of the stats means" -ForegroundColor Green
            Write-Host "they should be taken as a guide only." -ForegroundColor Green
        
        Write-Host "`n----- End of report for $ClusterSelection ----- `n" -foregroundColor Yellow

    }
} # end Get-EnvironmentResourceAudit
