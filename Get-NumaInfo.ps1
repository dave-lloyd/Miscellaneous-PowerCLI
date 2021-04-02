Function Get-NumaInfo {
    Get-VMHost | Sort-Object -Property Name | Select-Object name,
        @{Name = "Type"; Expression = {$_.ExtensionData.Hardware.NumaInfo.Type} },
        @{Name = "Number Node"; Expression = {$_.ExtensionData.Hardware.NumaInfo.NumNodes} }

        Write-Host "`nThis information is from the properties under ExtensionData.Hardware.NumaInfo" -ForegroundColor Green

} # end Get-NumaInfo