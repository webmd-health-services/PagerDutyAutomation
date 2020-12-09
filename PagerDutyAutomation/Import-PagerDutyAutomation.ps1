<#
.SYNOPSIS
Imports the PagerDutyAutomation module into the current session.

.DESCRIPTION
The `Import-PagerDutyAutomation function imports the PagerDutyAutomation module into the current session. If the module is already loaded, it is removed, then reloaded.

.EXAMPLE
.\Import-PagerDutyAutomation.ps1

Demonstrates how to use this script to import the PagerDutyAutomation module  into the current PowerShell session.
#>
[CmdletBinding()]
param(
)

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

$originalVerbosePref = $Global:VerbosePreference
$originalWhatIfPref = $Global:WhatIfPreference

$Global:VerbosePreference = $VerbosePreference = 'SilentlyContinue'
$Global:WhatIfPreference = $WhatIfPreference = $false

try
{
    if( (Get-Module -Name 'PagerDutyAutomation') )
    {
        Remove-Module -Name 'PagerDutyAutomation' -Force
    }

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'PagerDutyAutomation.psd1' -Resolve)
}
finally
{
    $Global:VerbosePreference = $originalVerbosePref
    $Global:WhatIfPreference = $originalWhatIfPref
}
