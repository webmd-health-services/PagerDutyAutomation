# PagerDutyAutomation

Functions for working with the PagerDuty APIs.

## System Requirements

PowerShell 5.1+

## Installation

```powershell
Install-Module -Name PagerDutyAutomation
```

## Commands

* Convert-PDExtension: converts v1/v2 extensions to v3 webhook subscriptions.
* Invoke-PDRestMethod: makes requests to the PagerDuty API.
* New-PDSession: creates a session object that is required for all functions that make a request to the PagerDuty API.

## Usage

```powershell
Import-Module -Name PagerDutyAutomation

$session = New-PDSession -Token $token

# Results paged by default; loop through them looking for what you want.
$offset = 0
do
{
    $page = Invoke-PDRestMethod -Session $session -Path 'services' -Offset $offset
    $offset += $page.limit
    # Do something with $page.services
}
while( $page.more )
```

If you don't want to manage paging, you have a few options.

```powershell
# Find a specific item. Stops making requests once an item is found.
$service = Invoke-PDRestMethod -Session $session -Path 'services' -First { $_.name -eq 'My Service' }

# Or, find all items that match a filter expression. Requests all items from PagerDuty
$services = Invoke-PDRestMethod -Session $session -Path 'services' -Filter { $_.name -like '*Service' }

# Return all objects.
$allServices = Invoke-PDRestMethod -Session $session -Path 'services' -All
```

If you have the URL to a specific object (i.e. from a `self` property on another object), pass its URL to the `Uri`
parameter:

```powershell
Invoke-PDRestMethod -Session $session -Uri $service.escalation_policy.self
```

You can create things by passing the JSON to the `Body` parameter *or* an object and `Invoke-PDRestMethod` will convert
it to JSON for you (using `ConvertTo-Json`):

```powershell
$body = [pscustomobject]@{ 'property' = 'value' }
Invoke-PDRestMethod -Session $session -Path 'some/endpoint' -Body $body -Method Post

$bodyJson = $body | ConvertTo-Json -Depth 50
Invoke-PDRestMethod -Session $session -Path 'some/endpoint' -Body $body -Method Post
```
