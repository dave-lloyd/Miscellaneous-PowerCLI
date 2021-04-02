# Wrapper to Get-ESXCli to retrieve NIC information from hosts
Function Get-NICDriver {
    $ESXiNICCollection = @() # Host worksheet collection
    $allESXiHosts = Get-VMHost 
    foreach ($ESXiHost in $allESXiHosts) {        
        $HostNICDetails = (Get-ESXcli -V2 -VMHost $ESXiHost).network.nic.list.Invoke()
        foreach ($HostNic in $HostNICDetails) {
            $ESXiNICInfo = [PSCustomObject]@{
                Host          = $ESXiHost.Name
                "NIC Name"    = $HostNIC.Name
                "NIC MAC"     = $HostNIC.MACAddress
                Description   = $HostNIC.Description
                "Link status" = $HostNIC.Link
                "Link Speed"  = $HostNIC.Speed
                "Driver type" = $HostNIC.Driver
                "MTU"         = $HostNIC.mtu 
            }
            $ESXINICCollection += $ESXiNICInfo                                 
        } # End foreach ($HostNic in $HostNICDetails)
    }
    $ESXINICCollection
} # end Get-NICDriver
