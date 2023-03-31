
# PagerDutyAutomation Changelog

## 1.0.0

## Added

* Parameter `Url` to function `Invoke-PDRestMethod` to replace the now-obsolete `Uri` parameter.
* `Convert-PDExtension` function for converting v1/v2 extensions to webhook subscriptions.

## Deprecated

* `Uri` parameter on `Invoke-PDRestMethod`. Use the new `Url` parameter instead.

## 0.1.2 (2023-01-11)

* Fixed: Invoke-PDRestMethod fails to write a proper error when the PagerDuty API doesn't return an error object.

## 0.1.1 (2021-05-04)

* Fixed: Invoke-PDRestMethod's default limit value (10000) fails.

## 0.1.0 (2020-12-10)

* Created New-PDSession function for holding session information.
* Created Invoke-PDRestMethod function for calling PagerDuty API endpoints.
