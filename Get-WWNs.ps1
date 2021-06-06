function Get-WWNs {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $False, Position = 1)]
		[string]$cluster = "*"
		
	)

    # List the WWN for all hosts in the vCenter
    $scope = Get-Cluster -Name $Cluster | Get-VMHost # All hosts in a specific cluster

    foreach ($esx in $scope){
        Write-Host "Host:", $esx -foregroundColor Magenta
        $hbas = Get-VMHostHba -VMHost $esx -Type FibreChannel
        foreach ($hba in $hbas){
            $wwpn = "{0:x}" -f $hba.PortWorldWideName
            Write-Host `t $hba.Device, "|", $hba.model, "|", "World Wide Port Name:" $wwpn
        }
        Write-Host

    }
} # end Get-WWNs function

