# PowerCLI-Snippets

This is a collection of snippets of code and functions for my reference. These are typically all in my Powershell profile for easy accessibility. 

Many are in essence just "wrappers" and glorified one-lines in order to give me that various options that I like to have for a task, without having to copy and paste code - eg, My-GetDetailedVM is essentially Get-VM with all the properties displayed that I want for a reasonably compreshensive overview of the VM. Also, I have used names such as Get-MyVM, Get-MyDatastore which highlight that they're just "my" version of those basic cmdlets.

At one point, some of them, or at least earlier versions, formed a "toolkit". Maybe at somepoint I will re-create something based on them again. 

# Script / functions

## VMs
* Get-MyVM.ps1                        :- Get-VM but with limited properties and ProvisionedSpaceGB formatted as I want it.
* Get-MyDetailedVM.ps1                :- Get-MyVM with additional properties.
* Get-VMIP.ps1                        :- returns IP from VM.
* Get-VMStorage.ps1                   :- returns disk usage from OS (needs VMwareTools running), virtual disks and datastore information for given VM.
* Get-VMToolsCheck.ps1                :- returns VMware Tools version and status.
* Get-PoweredOnVMs.ps1                :- count and details of all powered on VMs.
* Get-VMGuestOSList.ps1               :- Count of the different GuestOS types - VM needs to be powered on.
* Get-VMsOnDatastore.ps1              :- for a given VM, return details about the datastore AND list of all other VMs on that datastore.
* Get-VMEvents.ps1                    :- get tasks and events messages for specified VM.
* Get-VMHARestarts.ps1                :- returns or generates report of VM HA restarts events - in the event of a host failure/issue.

## Snapshots
* Get-SnapshotReport.ps1              :- Snapshot report for either VM or all VMs. Can be exported to .xlsx using Export-Excel

## Storage & RDMs
* Get-RDMList.ps1                     :- returns all VMs with RDMs attached.
* Get-VMsOnHost.ps1                   :- List all VMs on specified host, ordered by powerstate.
* Get-MyDatastore.ps1                 :- get-datastore but with figures rounded and percentage usage. 
* Get-DatastoreFileList               :- creates a .csv file with all the files in a specified datastore.
* Get-WWNs                            :- Get host WWNs for all hosts in specified cluster or vCenter

## Host
* Get-VMHostUptime.ps1                :- get host boot time and calculated uptime.
* Get-NICDriver.ps1                   :- return vmnic details - from Get-ESXCli -V2
* Get-VIBList.ps1                     :- return list of VIBs installed on host from Get-ESXCli -V2
* Get-HostProcessorTypeCount.ps1      :- count pf processor types in hosts.
* Get-HostModel.ps1                   :- count of host model types.
* Get-HostHyperthreading.ps1          :- count of hosts with hyperthreading enabled or disabled.

## vCenter
* Get-EnvironmentResourceAudit.ps1    :- Memory and CPU audit per cluster
* Get-HostMaintenanceModeCheck.ps1    :- Check if host should be able to enter maintenance mode 
* Get-HADRS.ps1                       :- Summary of HA and DRS settings for clusters.
* Get-VCVersion.ps1                   :- Returns vCenter name, version and build number.

## Networking
* Get-VMKInfo.ps1                     :- vmk info for hosts - wrapper mainly to Get-VMHostNetworkAdapter
