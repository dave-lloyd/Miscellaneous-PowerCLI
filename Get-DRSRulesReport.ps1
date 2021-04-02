Function Get-DRSRulesReport {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, Position = 1)]
        [ValidateSet('Yes', 'No')] # these are the only valid options
        [string]$GenerateReport
    )

    # DRS rules - based on code from somewhere - can't remember where to properly attribute
    # 2 sets - VM affinity/anti-affinity and VM to Host affinity
    $DRSRules = Get-Cluster | Get-DrsRule
    $VMAffinityRules = ForEach ($DRSRule in $DRSRules) {
        "" | Select-Object -Property @{N = "Cluster"; E = { (Get-View -Id $DRSRule.Cluster.Id).Name } },
            @{N = "Rule Name"; E = { $DRSRule.Name } },
            @{N = "Enabled"; E = { $DRSRule.Enabled } },
            @{N = "Rule Type"; E = { $DRSRule.Type } }, 
            @{N = "VMs"; E = { $VMIds = $DRSRule.VMIds -split "," 
            $VMs = ForEach ($VMId in $VMIds) { 
                (Get-View -Id $VMId).Name
            } 
            $VMs -join "," }
        }
    }

    # And now the VM host affinity rules
    $DRSRules2 = Get-Cluster | Get-DrsRule -Type VMHostAffinity
    $VMHostAffinityRules = ForEach ($DRSRule in $DRSRules2) {
        "" | Select-Object -Property @{N = "Cluster"; E = { (Get-View -Id $DRSRule.Cluster.Id).Name } },
            @{N = "Rule Name"; E = { $DRSRule.Name } },
            @{N = "Enabled"; E = { $DRSRule.Enabled } },
            @{N = "Rule Type"; E = { $DRSRule.Type } }, 
            @{N = "VMs"; E = { $VMIds = $DRSRule.VMIds -split "," 
            $VMs = ForEach ($VMId in $VMIds) { 
                (Get-View -Id $VMId).Name
            } 
            $VMs -join "," }
        }
    }

    # Ugh - combine the 2 sets of rules
    $AllDRSRules = $VMAffinityRules + $VMHostAffinityRules

    $AllDRSRules

    If ($GenerateReport -eq "Yes") {
        Write-Host "Generating Excel report." -ForegroundColor Green
        $date = Get-Date -Format "yyyy-MMM-dd-HHmmss"
        $xlsx_output_file = "$global:DefaultVIServer-DRSRules-$date.xlsx"
        $AllDRSRules | Export-Excel $xlsx_output_file -BoldTopRow -AutoFilter -FreezeTopRow -WorkSheetname "DRS Rules" -AutoSize 
        Write-Host "Report generated as : $xlsx_output_file" -ForegroundColor Green
    }
} # end Get-DRSRulesReport