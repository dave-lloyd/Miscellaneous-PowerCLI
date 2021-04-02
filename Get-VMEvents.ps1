# Essentially Get-VIEvent but with default sample of 100 if not supplied by user, and selected properties only displayed.
Function Get-VMEvents {
    <#
        .Synopsis
        Retrieve specified number of events associated with selected VM.
        .Description
        Retrieves the latest events associated with the selected VM. Number of events to retrieve is optional, but will default to 
        the last 100 if not specified.
        Properties returned are limited to :
        Full formatted message
        Username
        Created Time
        .PARAMETER vm
        The VM to retrieve events for.
        .PARAMETER numevents
        The number of events to retrieve. If not defined, it will default to the last 100.

    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, Position = 1)]
        [string]$vm,

        [Parameter(Mandatory = $False)]
        [String]$numEvents,

        [Parameter(Mandatory = $False)]
        [ValidateSet('Yes', 'No')] # these are the only valid options
        [string]$Export
        )

        # default to 100
        If (-not $numEvents) {
            $numEvents = 100
        }

        $EventList = Get-VM $vm | Get-VIEvent -MaxSamples $numEvents | Select-Object FullFormattedMessage, Username, CreatedTime | Sort-Object -Property CreatedTime -Descending 
        $EventList | Out-Host
        If ($Export -eq "Yes") {
            $OutputFile = "$vm-events.xlsx"
            $EventList | Export-Excel -$OutputFile -BoldTopRow -AutoFilter -FreezeTopRow -WorkSheetname "VM Events" -AutoSize
            Write-Host "Events exported as $OutputFile`n" -ForegroundColor Green
        }

        
} # end Get-VMEvents
