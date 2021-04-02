Function Get-NetworkCoredump {
    # Check 
    $allESXiHosts = Get-VMHost 
    foreach ($ESXiHost in $allESXiHosts) {        
        $esxcli = (Get-ESXcli -V2 -VMHost $ESXiHost).system.coredump.network.get.Invoke()
        Write-Host "Host : $EsxiHost"
        $esxcli
    }
} # end Get-NetworkCoredump