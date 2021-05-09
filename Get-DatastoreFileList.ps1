
function Get-DatastoreFileList{
        <#
        .SYNOPSIS
            Generates .csv file of the files located on specfied datastore
        
        .DESCRIPTION
            Generates .csv file of the files located on specfied datastore.
            A PD drive is created for the specified datastore, and contents sent to .csv.
            Only specific properties are exported, so more can be added if needed. 
            Properties exported are :
                name - file name
                datastore - datastore - arguably superflous
                folderpath - 
                itemtype - what type of file
                lastwritetime - last write time of the file
                length - size of the file
            CSV file is generated in the folder where the function is run from. Filename is the datastore name-files.csv

        .PARAMETER Datastore
    ​        Name of the datastore to export the contents of

        .EXAMPLE
            Get-DatastoreFileList -datastore datastore01   
            Will generate a file called datastore01-files.csv in the folder where the script is run.     
    #>

    [CmdletBinding()]   
    Param(
      [parameter(Mandatory=$true)]
      $Datastore
    )

    $outputFile = "$datastore-files.csv"

    try {
        $Datastore = Get-Datastore $Datastore -ErrorAction Stop
    } catch {
        Write-Host "`nDatastore doesn't exist with that name. Terminating script.`n" 
        Break
    }

    Write-Host "`n* Datastore exists. Creating PS Drive`n" -ForegroundColor Green
    New-PSDrive -Name DS -Location $Datastore -PSProvider VimDatastore -Root '\' -WhatIf:$false | Out-Null

    Write-Host "* Generating file list. This may take a few minutes." -ForegroundColor Green
    Get-ChildItem -Path DS: -Recurse | Select-Object name, datastore, folderpath, itemtype, lastwritetime,length | export-csv -NoTypeInformation $outputFile
    Write-Host ("* File list generated as {0}" -f $outputFile) -ForegroundColor Green

    Write-Host "`n* Removing PS Drive" -ForegroundColor Green
    Remove-PSDrive -Name DS

}
