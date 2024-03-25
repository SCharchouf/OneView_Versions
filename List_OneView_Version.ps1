<#
.SYNOPSIS
This script contains a function to import required modules if they are not already imported.

.DESCRIPTION
The Import-ModulesIfNotExists function checks if the required modules are already imported. 
If any of the required modules are missing, it displays an error message and exits the script. Otherwise, it imports the remaining modules.

.PARAMETER ModuleNames
Specifies an array of module names that need to be imported.

.EXAMPLE
$RequiredModules = @('HPEOneView.850', 'Microsoft.PowerShell.Security', 'Microsoft.PowerShell.Utility')
Import-ModulesIfNotExists -ModuleNames $RequiredModules

This example imports the required modules specified in the $RequiredModules array using the Import-ModulesIfNotExists function.

.NOTES
Author: CHARCHOUF SABRI
Date:   14/03/2024
Version : 1.0
#>
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$loggingFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\Logging_Function\Logging_Functions.ps1"
. $loggingFunctionsPath 
# Define the script version
$ScriptVersion = "1.1"
# Define the function to import required modules if they are not already imported
function Import-ModulesIfNotExists {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$ModuleNames
    )
    # Start logging
    Start-Log -ScriptVersion $ScriptVersion -ScriptPath $PSCommandPath
    # Get the log file path from the start-log function

    foreach ($ModuleName in $ModuleNames) {
        if (Get-Module -ListAvailable -Name $ModuleName) {
            if (-not (Get-Module -Name $ModuleName)) {
                Import-Module $ModuleName
                if (-not (Get-Module -Name $ModuleName)) {
                    $message = "`tFailed to import module '$ModuleName'."
                    Write-Log -Message $message -Level "Error" -sFullPath $global:sFullPath
                }
                else {
                    $message = "`tModule '$ModuleName' imported successfully."
                    Write-Log -Message $message -Level "OK" -sFullPath $global:sFullPath
                }
            }
            else {
                $message = "`tModule '$ModuleName' is already imported."
                Write-Log -Message $message -Level "Info" -sFullPath $global:sFullPath
            }
        }
        else {
            $message = "`tModule '$ModuleName' does not exist."
            Write-Log -Message $message -Level "Error" -sFullPath $global:sFullPath
        }
    }
}
# Import the required modules
Import-ModulesIfNotExists -ModuleNames 'HPEOneView.660', 'Microsoft.PowerShell.Security', 'Microsoft.PowerShell.Utility', 'ImportExcel'
# Define CSV file name
$csvFileName = "Appliances_List.csv"
# Create the full path to the CSV file
$csvFilePath = Join-Path -Path $scriptPath -ChildPath $csvFileName
# Define the path to the credential folder
$credentialFolder = Join-Path -Path $scriptPath -ChildPath "Encrypted_Credentials"
# Define the path to the credential file
$credentialFile = Join-Path -Path $credentialFolder -ChildPath "credential.txt"
# Import Appliances_List.csv file
Function Connect-OneViewAppliance {
    param (
        [string]$ApplianceFQDN,
        [PSCredential]$Credential
    )

    try {
        # Attempt to connect to the appliance
        Connect-OVMgmt -Hostname $ApplianceFQDN -Credential $Credential -ErrorAction Stop

        # If the connection is successful, log a success message
        $shortFQDN = ($ApplianceFQDN -split '\.')[0].ToUpper()
        $message = "Successfully connected to : $shortFQDN"
        Write-Log -Message $message -Level "OK" -sFullPath $global:sFullPath

        # Log a progress message
        $message = "Generating report for $shortFQDN..."
        Write-Log -Message $message -Level "Info" -sFullPath $global:sFullPath

        # Define the path to the Excel file
        $folderPath = Join-Path -Path $scriptPath -ChildPath "Oneview_Version_Report"
        $excelFilePath = Join-Path -Path $folderPath -ChildPath "Users_$shortFQDN.xlsx"

        # Get the OneView version
        $oneViewVersion = Get-HPOVVersion

        # Create an object with the required properties
        $outputObject = New-Object -TypeName PSObject
        $outputObject | Add-Member -MemberType NoteProperty -Name "Name" -Value $shortFQDN
        $outputObject | Add-Member -MemberType NoteProperty -Name "ApplianceVersion" -Value $oneViewVersion.ApplianceVersion
        $outputObject | Add-Member -MemberType NoteProperty -Name "LibraryVersion" -Value $oneViewVersion.LibraryVersion
        $outputObject | Add-Member -MemberType NoteProperty -Name "Path" -Value $oneViewVersion.Path

        # Export the object to an Excel file
        $outputObject | Export-Excel -Path $excelFilePath

        # Check if the folder exists and create it if it doesn't
        if (-not (Test-Path -Path $folderPath)) {
            New-Item -ItemType Directory -Path $folderPath | Out-Null
            $message = "Reports folder does not exist. Created new folder: $folderPath"
            Write-Log -Message $message -Level "Info" -sFullPath $global:sFullPath
        }
    }
    catch {
        # If a connection already exists, log a message and continue
        if ($_.Exception.Message -like "*already connected*") {
            $message = "Already connected to : $shortFQDN"
            Write-Log -Message $message -Level "Info" -sFullPath $global:sFullPath
        }
        else {
            # If the connection fails for any other reason, log an error message
            $message = "Failed to connect to : $shortFQDN. Error details: $($_.Exception.Message)"
            Write-Log -Message $message -Level "Error" -sFullPath $global:sFullPath
        }    
    }
}
# Check if the credential folder exists, if not, create it
if (!(Test-Path -Path $credentialFolder)) {
    Write-Log -Message "The credential folder $credentialFolder does not exist. Create it now..." -Level "Warning" -sFullPath $global:sFullPath
    New-Item -ItemType Directory -Path $credentialFolder | Out-Null
    Write-Log -Message "The credential folder $credentialFolder has been created successfully." -Level "OK" -sFullPath $global:sFullPath
}

# If the credential file exists, try to load the credential from it
if (Test-Path -Path $credentialFile) {
    try {
        $credential = Import-Clixml -Path $credentialFile
    }
    catch {
        Write-Host "Error loading credential file. Please enter your credentials."
        $credential = Get-Credential -Message "Enter your username and password"
        $credential | Export-Clixml -Path $credentialFile
    }
}
else {
    # If the credential file doesn't exist, ask for the username and password and store them in the credential file
    $credential = Get-Credential -Message "Enter your username and password"
    $credential | Export-Clixml -Path $credentialFile
}

# Import the CSV file and connect to each appliance
Import-Csv -Path $csvFilePath | ForEach-Object {
    Connect-OneViewAppliance -ApplianceFQDN $_.FQDN -Credential $credential
}