# What VMs are running on given host - ordered by powerstate
Function Get-VMsOnHost {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True, Position = 1)]
        [string]$vmhost
    )

    Write-Host "`nVMs on $vmhost : " -ForegroundColor Green
    Write-Host "Ordered by powerstate." -ForegroundColor Green
    Get-VMHost $vmhost | Get-VM | Sort-Object -Property "Powerstate"
} # end Get-VMsOnHost
