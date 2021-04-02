Function Get-VMToolsCheck {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $False, Position = 1)]
        [string]$vm
    )

    If ($vm) {
        Get-VM $vm | Select-Object @{n = "VM Name"; E = {$_.Name} }, Powerstate,
            @{ n = "Tools Status"; E = {$_.ExtensionData.Guest.ToolsStatus } },
            @{ n = "Tools Version"; E = {$_.ExtensionData.Guest.ToolsVersion } }, vmhost
    } else {
        Get-VM | Select-Object @{n = "VM Name"; E = {$_.Name} }, Powerstate,
            @{ n = "Tools Status"; E = {$_.ExtensionData.Guest.ToolsStatus } },
            @{ n = "Tools Version"; E = {$_.ExtensionData.Guest.ToolsVersion } }, vmhost
    }
} # end Get-VMToolsCheck
