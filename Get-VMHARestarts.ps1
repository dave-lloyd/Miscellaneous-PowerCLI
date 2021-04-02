
Function Get-VMHARestarts {
    <#
        .SYNOPSIS
            Checks for any VMs logged as restart by HA
        .DESCRIPTION
            Checks for any VMs logged as restarted by HA within the number of days passed, and within the number of event samples collected.
            This is basically a wrapper to Get-VIEvent and searching specfically for HA restart events.
            Four optional parameters - vc, numDays, MaxSamples and GenerateReport

        .PARAMETER vc
            vCenter to connect to. If not provided, script will check against the currently connected to vCenter. If no vCenter is 
            currently connected, the script would exit.
            If a vCenter is provided, any existing connection will be closed first, and then connection made to the specified vCenter.

        .PARAMETER numDays
            The number of days to go back - this is basically the Start parameter in Get-VIEvent
            Default if nothing is provided is 7 days
            If you know you are looking for within the last day, you can narrow this down, however keep in mind that it combines with
            MaxSamples, so if you said numDays 1 and MaxSample 100, and the actual event was in the last day, but would be the 150th
            sample, then no match would be returned.

        .PARAMETER MaxSamples
            The maximum number of events to gather to check. 
            Default if nothing is provided, is 1000

        .PARAMETER GenerateReport
            Yes/No
            If yes, AND alerts are found, a .csv report will be generated.

        .EXAMPLE
            Get-VMHARestarts
            IF you are currently connected to a vCenter, checks for VM HA restart events over 7 days and up to 1000 events. 
            If there were more than 1000 events in the 7 days, then MaxSamples would be the limiting parameter.
            If not currently connected to a vCenter, the script will exit.
            
        .EXAMPLE
            Get-VMHARestarts -vc vc.company.local -numDays 3 -MaxSamples 2000    
            If currently connected to vc.company.local, will gather up to 2000 samples or 3 days from the events.
            IF not connected to vc.company.local it will disconnect from the existing vCenter and try to connect to vc.company.local
            Any results will be output to .csv file and console.
            
        .EXAMPLE
            Get-VMHARestarts -vc vc.company.local -numDays 3 -MaxSamples 2000 -GenerateReport No
            As per previous example, but no .csv file will be generated.

    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $False, Position = 1)]
        $vc,
        [Parameter(Mandatory = $False)]
        $numDays = 7,
        [Parameter(Mandatory = $False)]
        $MaxSamples = 10000,
        [Parameter(Mandatory = $False)]
        [ValidateSet('Yes', 'No')] 
        [string]$GenerateReport = 'Yes' 
    )

    If ($vc) {
        # Are we connected to something - if so, disconnect
        If ($global:DefaultVIServer) {
            Disconnect-VIServer -Force -Confirm:$False
        }

        # If we're NOT currently connected to the specified VC, then try and connect. If it fails, bail.
        If ($global:DefaultVIServer.name -ne $vc) {
            try { 
                Connect-VIServer $vc -ErrorAction Stop
            } Catch {
                Write-Host "Unable to connect to VC"
                Break
            }
        }
    } else { # We're not connected to a VC and no VC was specified - so, we can't do anything. Exit the script.
        If ($global:DefaultVIServer -eq $null) {
            Write-Host "No VC specified, and not currently connected to any."
            Write-Host "Either connect first, or rerun with the -vc parameter"
            Break
        }
    }

    Write-Host "vCenter to check : $global:DefaultVIServer " -ForegroundColor Green
    Write-Host "Days back to check : $numDays" -ForegroundColor Green
    Write-Host "Maximum samples to check : $MaxSamples`n" -ForegroundColor Green
    Write-Host "`nGathering events to check for any logged VM HA restarts" -ForegroundColor Green
    $GetEnvironmentEvents = Get-VIEvent -Start (Get-Date).AddDays(-$numDays) -MaxSamples $MaxSamples -Types Warning 
    
    $HARestarts = $GetEnvironmentEvents | Where-Object { $_.FullFormattedMessage -like "*vSphere HA restarted virtual machine*" }
    If ($HARestarts.count -gt 0) {
        $GeneratedResults = $HARestarts| Select-Object @{ Name = "VM"; Expression = {$_.ObjectName}}, CreatedTime, FullFormattedMessage
        If ($GenerateReport -eq "Yes") {
            Write-Host "VMs list : " -ForegroundColor Cyan
            $HARestarts| Select-Object @{ Name = "VM"; Expression = {$_.ObjectName}} | Out-Host
            $VCName = $global:DefaultVIServer.name
            $date = Get-Date -Format "yyyy-MMM-dd-HHmmss"
            $csv_output_file = "$VCName-VMHARestarts-Audit-$date.csv"
            Write-Host "Events : " -ForegroundColor Cyan
            $GeneratedResults | Export-CSV -NoTypeInformation -Path $csv_output_file
            $GeneratedResults | Format-List
            Write-Host "Report generated : $csv_output_file"
        } else {
            Write-Host "VMs list : " -ForegroundColor Cyan
            $HARestarts| Select-Object @{ Name = "VM"; Expression = {$_.ObjectName}}
            Write-Host "Events : " -ForegroundColor Cyan
            $GeneratedResults | Format-List
        }
    } else {
        Write-Host "No events found."
    }
} # End Get-VMHARestarts
