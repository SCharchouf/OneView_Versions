# The script assumes there's a separate file named Logging_Functions.ps1 containing functions for logging messages
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$loggingFunctionsPath = Join-Path -Path $scriptPath -ChildPath "..\Logging_Function\Logging_Functions.ps1"
. $loggingFunctionsPath 
# Script Version
$scriptVersion = "1.1"
# Script Path Gets the path to the directory where the script resides using Split-Path and $MyInvocation.MyCommand.Definition.
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
# Importing Required Modules
function Import-RequiredModules {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$moduleNames
    )

    $missingModules = @()  # Empty list to store any missing modules
    $importedModules = @()  # Empty list to store imported modules

    # Check what modules you have on hand
    $availableModules = Get-Module -ListAvailable -Name $moduleNames

    # See if any modules are missing from your toolbox
    foreach ($moduleName in $moduleNames) {
        if (-not ($availableModules | Where-Object { $_.Name -eq $moduleName })) {
            $missingModules += $moduleName
        }
    }

    # If some modules are missing, yell about it and then exit
    if ($missingModules.Count -gt 0) {
        Write-Log -Message "Uh oh! Missing modules: $($missingModules -join ', ')" -Level "Error" -sFullPath $global:sFullPath
        Exit 1
    }

    # If all modules are present, import the ones you need
    foreach ($moduleName in $moduleNames) {
        if (-not (Get-Module -ListAvailable -Name $moduleName)) {
            Import-Module $moduleName
            $importedModules += $moduleName
        }
    }

    # Log which modules you snagged from the toolbox
    if ($importedModules.Count -gt 0) {
        Write-Log -Message "Imported these modules: $($importedModules -join ', ')" -Level "OK" -sFullPath $global:sFullPath
    }

}
$requiredModules = @('HPEOneView.660', 'Microsoft.PowerShell.Security', 'Microsoft.PowerShell.Utility', 'ImportExcel')
Import-RequiredModules -moduleNames $requiredModules
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------
# --------------------------------------------------------------------------- [Script Variables] ----------------------------------------------------------------
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------
# Construct the CSV path with clarity and error handling
$csvPath = Join-Path $scriptPath -ChildPath "..\Appliances_List\Appliances_List.csv"
# Validate the CSV file's existence before importing
if (Test-Path $csvPath) {
    # Import the CSV data, leveraging parameter splatting for readability
    Import-Csv @{
        Path = $csvPath
        # Specify delimiter if needed (example: -Delimiter ";")
    }

    # Log a clear message with structured formatting
    Write-Log -Message "CSV data imported successfully from $csvPath" -Level "Information" -sFullPath $global:sFullPath
} else {
    # Handle the missing file scenario gracefully
    Write-Error "CSV file not found at $csvPath. Please verify the path or file existence."
}
