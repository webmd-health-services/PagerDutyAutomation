
function Convert-PDExtension
{
    <#
    .SYNOPSIS
    Converts v1/v2 extensions to v3 webhook subscriptions.

    .DESCRIPTION
    The `Convert-PDExtension` function converts v1/v2 extensions to v3 webhook subscriptions. For each extension, it
    checks that there is no existing webhook subscription with the same name and endpoint URL, and if so, creates a new
    webhook subscription. The v1/v2 extension is not modified or deleted.

    This function uses the `/extensions` endpoint to get extensions and the `/webhook_subscriptions` endpoint to get and
    create webhook subscriptions.

    Use the `New-PDSession` function to create a session object.

    .EXAMPLE
    Convert-PDExtension -Session $pdSession

    Demonstrates how to call this function.
    #>
    [CmdletBinding()]
    param(
        # The session object for PagerDuty. Use New-PDSession to create a session object.
        [Parameter(Mandatory)]
        [Object] $Session
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $currentSubs = Invoke-PDRestMethod -Session $Session -Path 'webhook_subscriptions'

    foreach ($extension in (Invoke-PDRestMethod -Session $Session -Path '/extensions').extensions)
    {
        $existingSub =
            $currentSubs.webhook_subscriptions |
            Where-Object 'description' -EQ $extension.name |
            Where-Object { $_.delivery_method.url -eq $extension.endpoint_url }

        if ($existingSub)
        {
            Write-Verbose "$($extension.extension_schema.summary) ""$($extension.name)"" already migrated."
            continue
        }

        foreach ($target in $extension.extension_objects)
        {
            $v3Body = @"
{
    "webhook_subscription": {
        "delivery_method": {
            "type": "http_delivery_method",
            "url": $($extension.endpoint_url | ConvertTo-Json)
        },
        "description": $($extension.name | ConvertTo-Json),
        "events": [
            "incident.acknowledged",
            "incident.annotated",
            "incident.delegated",
            "incident.escalated",
            "incident.priority_updated",
            "incident.reassigned",
            "incident.reopened",
            "incident.resolved",
            "incident.responder.added",
            "incident.responder.replied",
            "incident.triggered",
            "incident.unacknowledged"
        ],
        "filter": {
            "id": $($target.id | ConvertTo-Json),
            "type": "service_reference"
        },
        "type": "webhook_subscription"
    }
}
"@
            [Uri] $endpointUrl = $extension.endpoint_url
            $msg = "Converting $($extension.extension_schema.summary) ""$($target.summary)"", endpoint " +
                   "$($endpointUrl.scheme)://$($endpointUrl.Authority), to v3 webhook subscription."
            Write-Information $msg
            Invoke-PDRestMethod -Session $session -Path '/webhook_subscriptions' -Body $v3Body -Method Post
        }
    }
}