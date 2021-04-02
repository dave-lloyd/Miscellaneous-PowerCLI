Function Get-vmxFileList {
    $vmxFileList = Get-VM | Select-Object Name,
        @{ n = "vmx File"; E = {$_.ExtensionData.Summary.Config.VmPathName}}
    $vmxFileList | Out-Host
} # end Get-vmxFileList
