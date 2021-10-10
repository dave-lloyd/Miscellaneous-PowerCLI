Function Get-VMNIC {
    <#
    .SYNOPSIS
        Return VM NIC details for specified VM, VMs in specified cluster or all VMs in environment

    .DESCRIPTION
        Return VM NIC details for specified VM, VMs in specified cluster or all VMs in environment
        It is effectively a wrapper to using the Get-NetworkAdapter cmdlets, filtering for specific properties.
        Properties returned :
            VM name,
            Network Adapater Name
            Type
            Network Name (portgroup)
            MacAddress 
            Connection state
        The output can be export to .csv using Export-CSV or to .xlsx using Export-Excel cndlets

    .PARAMETER VM
        Specify the VM to target

    .PARAMETER Cluster
        Name of the cluster to target for all VMs in that cluster.
        If neither VM or Cluster are specified, the script will return details for ALL VMs found.

    .EXAMPLE
        Get-VMNIC -vm <vmA>
        Will output the network adapter details of vmA

    .EXAMPLE
        Get-VMNIC -Cluster <clusterA> | Format-Table -Autosize
        Will output the network adapter details for all VMs found in cluster clusterA, and format as table rather than list 

    .EXAMPLE
        Get-VMNIC
        Will output the network adapter details for all VMs found in the environment.

    .EXAMPLE
        Get-VMNIC -Cluster <clusterA> | Export-CSV -NoTypeInformation <outputfile.csv>
        Will output the network adapter details for all VMs found in cluster clusterA to a .csv file call outputfile.csv
        
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $False)]
        [String]$vm,
        [Parameter(Mandatory = $False)]
        [String]$cluster
    )

    If (-not($vm) -and -not($cluster)) {
        $vm = "*"
    }

    if ($vm) {
        If ($vm -ne "*") {
            Try {
                Get-VM $VM -ErrorAction Stop | Out-Null
            } Catch {
                Write-Host "VM not found. Exiting."
                Break
            }
        }
        Get-VM $vm | Get-NetworkAdapter | Select-Object parent, name, type, networkname, macaddress, ConnectionState | sort-object -Property parent, name 
    } elseif ($Cluster) {
        Try { 
            Get-Cluster $Cluster -ErrorAction Stop | Out-Null
        } Catch {
            Write-Host "No such cluster"
            Break
        }
        Get-Cluster $Cluster | Get-VM | Get-NetworkAdapter | Select-Object parent, name, type, networkname, macaddress, ConnectionState | sort-object -Property parent -ErrorAction SilentlyContinue
    } else {
        Write-Host "We encountered an error"
    }
}