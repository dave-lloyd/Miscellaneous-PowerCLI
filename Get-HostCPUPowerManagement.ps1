Function Get-HostCPUPowerManagement {
    Get-VMHost | Sort-Object -Property Name | Select-Object name,
        @{Name = "CPU Power Management Policy"; Expression={$_.ExtensionData.Hardware.CpuPowerManagementInfo.CurrentPolicy} }, 
        @{Name = "Hardware Support"; Expression = {$_.ExtensionData.Hardware.CpuPowerManagementInfo.HardwareSupport} }

        Write-Host "`nThis information is from the properties under ExtensionData.Hardware.CpuPowerManagmentInfo" -ForegroundColor Green
} # end Get-HostCPUPowerManagement
