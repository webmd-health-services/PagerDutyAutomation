
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-PagerDutyAutomationTest.ps1' -Resolve)

Describe 'New-PDSession' {
    It 'should create session object' {
        $session = New-PDTestSession
        $session | Should -Not -BeNullOrEmpty
        $session.Token | Should -Not -BeNullOrEmpty
        $session.Url | Should -Be 'https://api.pagerduty.com'
    }
}
