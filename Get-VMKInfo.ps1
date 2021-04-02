Function Get-VMKInfo {
    $hostCollection = @() # Create a collection of all the ESXi hosts tested. 
    $Hosts = Get-VMHost 
    ForEach ($ESXiHost in $Hosts) {
        $HostInfo = Get-VMHostNetworkAdapter -VMHost $ESXiHost -VMKernel | Select-Object name, ip, subnetmask, devicename, vmhost, portgroupname, mtu, vMotionEnabled, ManagementTrafficEnabled
        $PGInfo = Get-VDPortgroup -Name $HostInfo.portgroupname
        $vmkinfo = [PSCustomObject]@{
            "Host"            = $Hostinfo.vmhost
            "vmk"             = $Hostinfo.name
            "Device name"     = $Hostinfo.devicename
            "IP"              = $Hostinfo.ip
            "Subnet mask"     = $Hostinfo.subnetmask
            "VDSwitch"        = $PGInfo.VirtualSwitch
            "Portgroup"       = $Hostinfo.portgroupname
            "VLAN"            = $PGInfo.vlanConfiguration
            "MTU"             = $Hostinfo.mtu
            "vMotion"         = $Hostinfo.vMotionEnabled
            "Host management" = $Hostinfo.ManagementTrafficEnabled
        } # end $Hostinfo = [PSCustomObject]@
        $HostCollection += $vmkinfo
    }
    $HostCollection #| Out-Host
} # end Get-VMKInfo
