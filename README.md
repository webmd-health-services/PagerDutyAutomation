0# PagerDutyAutomation

Functions for working with the PagerDuty APIs.

# System Requirements

PowerShell 5.1+

# Installation

```powershell
Install-Module -Name PagerDutyAutomation
```

# Usage

```powershell
Import-Module -Name PagerDutyAutomation
$session = New-PDSession -Token $token

# Results paged by default; loop through them looking for what you want.
$offset = 0
do
{
    $page = Invoke-PDRestMethod -Session $session -Path 'services' -Offset $offset
    $page.services | Write-Output
    if( $page.offset )
    {
        $offset += $page.offset
    }
}
while( $page.offset )

# Find a specific item.
$service = Invoke-PDRestMethod -Session $session -Path 'services' -First { $_.name -eq 'My Service' }

# Or, find all items that match a filter expression.
$service = Invoke-PDRestMethod -Session $session -Path 'services' -Filter { $_.name -like '*Service' }
```