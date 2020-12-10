
function New-PDSession
{
    <#
    .SYNOPSIS
    Creates a PagerDutyAutomation session object.

    .DESCRIPTION
    The `New-PDSession` function creates a PagerDutyAutomation session object. This object contains the API token and the
    URL to the PagerDuty API to use. This object should be passed to all PagerDutyAutomation commands.

    .EXAMPLE
    $session = New-PDSession -Token 'my_secret_token'

    Demonstrates how to create a PagerDutyAutomation session object.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [String]$Token
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    
    return [pscustomobject]@{
        'Token' = $Token;
        'Url' = 'https://api.pagerduty.com';
    }
}
