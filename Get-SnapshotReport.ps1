# Snapshot report. You can export this directly to Excel by running :
# Get-SnapshotReport | Export-Excel <filename.xlsx> -BoldTopRow -AutoFilter -FreezeTopRow -WorkSheetname "Snapshot report" -AutoSize    
Function Get-SnapshotReport {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $False, Position = 1)]
        [string]$vm
    )

    $snapshotCollection = @()

    # We're either going to report on a single VM (if a VM name is passed for $vmForReport) or all 
    # snapshots we can find
    If ($vm) {
        Write-Host "Check for snaphosts on a specified VM." -ForegroundColor Green
        Write-Host "--------------------------------------" -ForegroundColor Green
        #$vmToCheck = $vm
        $dcs = Get-VM $vm | Get-Datacenter
    } else {
        $vm = "*"
        $dcs = Get-Datacenter 
        Write-Host "Generate detailed report of all snapshots." -ForegroundColor Green
        Write-Host "------------------------------------------" -ForegroundColor Green
    }

    foreach ($dc in $dcs) {
        Write-Host "`nProcessing Snapshots information in datacenter : $dc." -ForegroundColor Green
        foreach ($snap in Get-VM -Name $vm -Location $dc | Get-Snapshot -ErrorAction SilentlyContinue) {
            # Let's see if we can work out who took the snapshot. It would be nice if Get-Snapshot returned the user but it appears it doesn't
            # So, we try to get the events that correspond to taking snapshots. There may be more than 1 - if so, take the latest one as being 
            # what we need. If we don't find anything, report unknown.
            $snapshotEvent = Get-VIEvent -Entity $snap.VM -Types Info -Finish $snap.Created.AddMinutes(10) | Where-Object {$_.FullFormattedMessage -imatch 'Task: Create virtual machine snapshot'}
            if ($snapshotEvent -ne $null) {
                If ($snapshotEvent.count -gt 1) {
                    $SnapshotEvent = $SnapshotEvent | Sort-Object -Property CreatedTime | Select-Object -Last 1 
                }
                $CreatedBy = $SnapshotEvent.Username
            } else {
                $CreatedBy = "Unknown"
            }

            $ds = Get-Datastore -VM $snap.vm
            $datastorePercentageFree = $ds | Select-Object @{N = "PercentFree"; E = { [math]::round($_.FreeSpaceGB / $_.CapacityGB * 100) } }
            $SnapshotAge = ((Get-Date) - $snap.Created).Days
        
            $snapinfo = [PSCustomObject]@{
                "VM"                        = $snap.vm
                "Snapshot Name"             = $snap.name
                "Description"               = $snap.description
                "Created"                   = $snap.created
                "Created by"                = $CreatedBy
                "Snapshot age (days)"       = $SnapshotAge
                "Snapshot size (GB)"        = [math]::round($snap.sizeGB)
                "Datastore"                 = $ds[0].name
                "Datastore free space (GB)" = [math]::round($ds[0].FreeSpaceGB)
                "Datastore percent free (%)" = $datastorePercentageFree.PercentFree
                "Current snapshot"          = $snap.IsCurrent
                "Memory state"              = $snap.Powerstate
                "Quiesced"                  = $snap.Quiesced
            } # end $snapinfo = [PSCustomObject]@
            $snapshotCollection += $snapinfo
        }

        If ($snapshotCollection.count -eq 0) {
            Write-Host "`nNo Snapshots reported." -ForegroundColor Green
            Break
        }

        $snapshotCollection #| Out-Host
    }
} # end Get-SnapshotReport
