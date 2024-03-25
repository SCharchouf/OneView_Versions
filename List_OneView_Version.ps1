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
    # Start logging
    Start-Log -ScriptVersion $ScriptVersion -ScriptPath $PSCommandPath
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
$requiredModules = @('HPEOneView.660', 'Microsoft.PowerShell.Security', 'Microsoft.PowerShell.Utility', 'ImportExcel')
Import-RequiredModules -moduleNames $requiredModules
