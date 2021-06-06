Function Get-VCVersion {
    if ($global:DefaultVIServer -ne $null) {
        $VC = $global:DefaultVIServer.name
        $Version = $global:DefaultVIServer.version
        $Build = $global:DefaultVIServer.build           

        Write-Host "vCenter details :" 
        Write-Host ("vCenter : {0}" -f $VC)
        Write-Host ("Version : {0}" -f $Version)
        Write-Host ("Build   : {0}" -f $build)
    } else {
        Write-Host "It appears you're not connected to a vCenter. Terminating script."
    }
} # End Get-VCVersion

