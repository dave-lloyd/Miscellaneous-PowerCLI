function New-MultiVMSnaphot {
    <#
        .Synopsis
            Take snapshots (memory included, no quiescing) for multiple VMs based on VM names containined in .csv file.

        .DESCRIPTION
            The script will read in a list of VMs from a supplied .csv file, and then attempt to take a snapshot for 
            each of the VMs.

            The .csv file should contain a column called "name" and an entry for each VM you wish to take the snapshot of.
            The name needs to be an exact match for the VM as it appears in the vCenter.

            If the name exists, the script will then check to see if there is more space on the underlying datastore, 
            than memory allocated to the VM. If not, then it will skip taking the snapshot, because of the risk of filling 
            the datastore.

            If will then check to see if there's at least 10% free space on the datastore - if not, again, it will skip 
            taking the snapshot for risk of filling the datastore. 

            If all the checks (name and space on datastore) pass, then it will proceed to attempt to take the snapshot. 
            The snapshot will be taken to include memory, but NOT to include quiescing.

            The name of the snapshot will be the Ticket number provided when running the script.
            The description for the snapshot will be the description provided when running the script.

            Once this has been processed for each VM, 2 possible "reports" will be displayed.

            The first will be the list of all the VMs for which the snapshots were successfully taken, and will 
            include certain amount of detail per snapshot, such as name, description, date taken, datastore etc. 

            The second will be the list of VMs for which snapshots were NOT taken, along with a reason, such as VM not 
            found, datastore not having sufficient free space, or an error being encountered when taking the snapshot. 

            KNOWN ISSUE :
            At this point the script does NOT make any check on whether the VM has an existing snapshot. So, if it does, 
            as long as it passes the check for VM existing and free space on the datastore, it will still proceed with 
            taking the snapshot. However, the "report" will give an error. You can still run Get-VM <vmname> | Get-Snapshot 
            to return the list of snapshots on the VM.

        .PARAMETER Name
            Mandatory parameter - this will be used as the Snapshot name for each VM

        .PARAMETER srcFile
            Mandatory parameter to provide the name of the .csv file, containing the list of VMs to snapshot. If this 
            is in a different directory to where the script is being run from, then provide the full path and filename

        .PARAMETER Description
            Mandatory parameter to provide a brief description.

        .EXAMPLE
            New-MultiVMSnapshot -Name "Snapshot pre patching" -srcFile vmlist.csv -Description "Snapshots for all"

            Will search for file vmlist.csv in the current directory, and import this and proceed to attempt to take 
            snapshots for all VMs listed in the file providing the snapshot name and brief description. Snapshots will
            include memory but NOT quiescing.

        .NOTES
        Author          : Dave Lloyd
        Version         : 0.1
        #>   

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, Position = 1)]
        [string]$Name,

        [Parameter(Mandatory = $True)]
        [string]$srcFile,

        [Parameter(Mandatory = $True)]
        [string]$Description 
    )

    # Collections - used for outputting results
    $snapshotCollection = @() # VMs for which snapshot is successfully taken
    $failedSnapshotCollection = @() # VMs that fail criteria, or for which the snapshot creation fails.

    Write-Host "`n----- Snapshot creation for multiple VMs. ------`n" -ForegroundColor Green

    # Check if the supplied file exists. If not, quit. IF ok, import it.
    Write-Host "`nChecking srcfile exists." -ForegroundColor Green
    If (-not (Test-Path -path $srcFile)) {
        Write-Host "File doesn't exist." -ForegroundColor Green
        Write-Host "`tPlease create a .csv file, with a column called 'name' and an entry for each VM to snapshot"
        Write-Host "`tThe name for each VM needs to be a complete match to the name of the VM as it appears in the vCenter."
        Write-Host "`nTerminating script.`n"
        Break
    }
    Write-Host "`tFile exists. Importing file." -ForegroundColor Green
    $vmsToSnap = Import-Csv $srcFile

    # A few checks as to if snapshot can/should be taken.
    # does the vm exist
    # does the underlying datastore have more free space than the memory allocated to the VM
    # does the datastore have 10% free space - preferred for caution
    Write-Host "`nReviewing and taking snapshots where possible." -ForegroundColor Green
    Write-Host "-----------------------------------------------" -ForegroundColor Green
    ForEach ($vm in $vmsToSnap) {
        $VMFound = $True
        $QCPassed = $True # Flag for whether to skip taking a snapshot.
        $IncludeInReport = $False
        $IncludeInErrorReport = $False

        # VM exists check
        Try {
            $CurrentVM = Get-VM $VM.name -ErrorAction Stop 
        } Catch {
            Write-Host $vm.name " : Unable to find VM with the name."
            #$QCPassed = $False
            $VMFound = $False
            $IncludeInErrorReport = $True
            $FailureMessage = "Unable to find VM with the name"
        }

        If ($VMFound) {
            # Check datastores for free space and percentage free. If it would be less than zero
            # or under 10%, then "fail" the check, and we'll skip taking the snapshot.
            $vmmemory = $CurrentVM.MemoryGB
            $DS = $CurrentVM | Get-Datastore
            $dsfree = [math]::round($ds[0].FreeSpaceGB)
            $temp = $dsfree - $vmmemory
            $dscapacity = [math]::Round($ds[0].CapacityGB)
            $percentagefree = [math]::Round(($dsfree / $dscapacity) * 100)
            
            if ($temp -lt 0) {
                Write-Host "$currentVM : Free space on datastore is less than VM Memory. No snapshot taken."  
                $QCPassed = $False  
                $IncludeInErrorReport = $True
                $FailureMessage = "Free space on datastore is less than VM Memory."
            }

            if ($percentagefree -lt 40) {
                Write-Host "$currentVM : Free space on datastore is less than 10%. No snapshot taken."    
                $QCPassed = $False
                $IncludeInErrorReport = $True
                $FailureMessage = "Free space on datastore is less than 10%."
            } 

            # Take snapshot if $QCFailed = $False
            If ($QCPassed) {
                Try {
                    $CurrentVM | New-Snapshot -Name $Name -Description $Description -Memory -ErrorAction Stop | Out-Null
                    Write-Host "$currentVM : Snapshot taken."
                    $IncludeInReport = $True
                } catch {
                    Write-Host "$currentVM : Encountered an error taking the snapshot."
                    $IncludeInErrorReport = $True
                    $FailureMessage = "Encountered an error taking the snapshot."
                }        
            } 
        } # end if ($QCPassed)

        if ($IncludeInReport) {
            $snap = Get-VM -Name $CurrentVM | Get-Snapshot -ErrorAction SilentlyContinue
            $ds = Get-Datastore -VM $snap.vm
            $datastorePercentageFree = $ds | Select-Object @{N = "PercentFree"; E = { [math]::round($_.FreeSpaceGB / $_.CapacityGB * 100) } }
            $snapinfo = [PSCustomObject]@{
                "VM"                         = $snap.vm
                "Snapshot Name"              = $snap.name
                "Current snapshot?"          = $snap.IsCurrent
                "Description"                = $snap.description
                "Created"                    = $snap.created
                "Snapshot size (GB)"         = [math]::round($snap.sizeGB)
                "Datastore"                  = $ds[0].name
                "Datastore free space (GB)"  = [math]::round($ds[0].FreeSpaceGB)
                "Datastore percent free (%)" = $datastorePercentageFree.PercentFree
                "Current snapshot"           = $snap.IsCurrent
                "Memory state"               = $snap.Powerstate
                "Quiesced"                   = $snap.Quiesced
            } 
            $snapshotCollection += $snapinfo
        }        

        If ($IncludeInErrorReport) {
            $failedVMList = [PSCustomObject]@{
                "VM"                 = $vm.name
                "Reason for failure" = $FailureMessage
            }
            $failedSnapshotCollection += $failedVMList
        }

    } # end foreach ($vm in $vmsToSnap)

    Write-Host "`nReports" -ForegroundColor Green
    Write-Host "-------" -ForegroundColor Green

    If ($snapshotCollection.count -gt 0) {
        Write-Host "`nSuccessful snapshots" -ForegroundColor Green
        $snapshotCollection | Out-Host 
    }

    If ($failedSnapshotCollection.count -gt 0) {
        Write-Host "VMs that failed to have snapshot taken for whatever reason - review" -ForegroundColor Green
        $failedSnapshotCollection | Out-Host
    }
    Write-Host "`nComplete. Terminating script."
} # end function New-MultiVMSnapshot