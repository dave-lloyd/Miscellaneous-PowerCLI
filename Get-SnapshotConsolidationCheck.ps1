function Get-SnapshotConsolidationCheck {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $False, Position = 1)]
        [ValidateSet('Yes', 'No')] # these are the only valid options
        [string]$Report = "No" # default to no if parameter not supplied
        
    )
$SnapshotConsolidationMessage = @"

Checking for any VMs that are marked as needing consolidation.

We are checking the value of ExtensionData.Runtime.ConsolidationNeeded for each VM.
TRUE = consolidation required.
FALSE = no consolidation required.
Only those with the value equal to TRUE will be reported. 

"@

    $SnapshotConsolidationMessage

    $snapshotConsolidationCollection = @()
    $dcs = Get-Datacenter
    ForEach ($dc in $dcs) {
        ForEach ($vm in Get-VM -Location $dc) {
            If ($vm.ExtensionData.Runtime.ConsolidationNeeded) {
                $snapinfo = [PSCustomObject]@{
                    "VM"                        = $vm.name
                    "Consolidation needed"      = $vm.ExtensionData.Runtime.ConsolidationNeeded
                }
                $snapshotConsolidationCollection += $snapinfo
            } 
        }
    }

    If ($snapshotConsolidationCollection.count -eq 0) {
        Write-Host "`nNo VMs with snapshots needing consolidation found." -ForegroundColor Green
    } else {
        $snapshotConsolidationCollection | Out-Host
#        $GenerateReport = Read-Host "Do you want to export this report to Excel - Y/N?"
        If ($GenerateReport -eq "Yes") {
            $date = Get-Date -Format "yyyy-MMM-dd-HHmmss"
            $xlsx_consolidation_output_file = "$Global:Reports_home\$global:DefaultVIServer-ConsolidationReport-$Date.xlsx"     
            $snapshotConsolidationCollection | Export-Excel $xlsx_consolidation_output_file -BoldTopRow -AutoFilter -FreezeTopRow -WorkSheetname Snapshots -AutoSize 
            Write-Host "`nReport generated : $xlsx_consolidation_output_file" -ForegroundColor Green
        }
    }    
} # end Get-SnapshotConsolidationCheck 