Function Set-DisableNetworkCoredump {
    # Disable
    $allESXiHosts = Get-VMHost 
    foreach ($ESXiHost in $allESXiHosts) {        
        $esxcli = (Get-ESXcli -V2 -VMHost $ESXiHost)
        $arguments = $esxcli.system.coredump.network.set.CreateArgs()
        $arguments.enable = "$False"
        Write-Host "Disabling for : $ESXiHost" -ForegroundColor Green
        $arguments = $esxcli.system.coredump.network.set.Invoke($arguments)
        # And check again and report
        $esxcli = (Get-ESXcli -V2 -VMHost $ESXiHost).system.coredump.network.get.Invoke()
        $esxcli | Select-Object Enabled | Out-Host
        $arguments = $null
    }
} # end Set-DisableNetworkCoredump
