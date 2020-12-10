
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-PagerDutyAutomationTest.ps1' -Resolve)

$session = New-PDTestSession

Describe 'Invoke-PDRestMethod.when endpoint pages results' {
    It 'should return page object' {
        $page = Invoke-PDRestMethod -Session $session -Path 'services'
        $page | Should -Not -BeNullOrEmpty
        $page.more | Should -BeTrue
        $page.offset | Should -Be 0
        $page.limit | Should -Be 25
        $page.total | Should -BeNullOrEmpty
        $page.services | Should -HaveCount 25

        $page1FirstService = $page.services | Select-Object -First 1

        $page = Invoke-PDRestMethod -Session $session -Path 'services' -Offset $page.limit
        $page | Should -Not -BeNullOrEmpty
        $page.more | Should -Not -BeNullOrEmpty
        $page.offset | Should -Be 25
        $page.limit | Should -Be 25
        $page.total | Should -BeNullOrEmpty
        $page.services | Should -HaveCount 25
        # Make sure it actually returns a new page of results.
        $page.services |
            Select-Object -First 1 |
            Select-Object -ExpandProperty 'id' |
            Should -Not -Be $page1FirstService.id
    }
}

Describe 'Invoke-PDRestMethod.when requesting total objects in a paged endpoint' {
    It 'should return total number of objects' {
        $page = Invoke-PDRestMethod -Session $session -Path 'services' -IncludeTotal
        $page | Should -Not -BeNullOrEmpty
        $page.total | Should -Not -BeNullOrEmpty
    }
}

Describe 'Invoke-PDRestMethod.when requesting custom number of objects from paged endpoint' {
    It 'should return more than the default number of objects' {
        $page = Invoke-PDRestMethod -Session $session -Path 'services'
        $defaultCount = $page.services | Measure-Object | Select-Object -ExpandProperty 'Count'
        $page = Invoke-PDRestMethod -Session $session -Path 'services' -Count 10000
        $page | Should -Not -BeNullOrEmpty
        $page.services | Measure-Object | Select-Object -ExpandProperty 'Count' | Should -BeGreaterThan $defaultCount
    }
}

Describe 'Invoke-PDRestMethod.when requesting a single object' {
    It 'should return just that object' {
        $lastService = Invoke-PDRestMethod -Session $session -Path 'services' -All | Select-Object -Last 1
        
        $result = Invoke-PDRestMethod -Session $session -Path 'services' -First { $_.id -eq $lastService.id }
        $result | Should -Not -BeNullOrEmpty
        $result.id | Should -Be $lastService.id
    }
}

Describe 'Invoke-PDRestMethod.when filtering results' {
    It 'should return all objects that match' {
        $idsToFind =
            Invoke-PDRestMethod -Session $session -Path 'services' -All |
            Select-Object -Last 3 |
            Select-Object -ExpandProperty 'id'

        $results = Invoke-PDRestMethod -Session $session -Path 'services' -Filter { $_.id -in $idsToFind }
        $results | Should -HaveCount 3
        $results[0].id | Should -Be $idsToFind[0]
        $results[1].id | Should -Be $idsToFind[1]
        $results[2].id | Should -Be $idsToFind[2]
    }
}

Describe 'Invoke-PDRestMethod.when api throws an error' {
    It 'should write error' {
        { Invoke-PDRestMethod -Session $session -Path 'services/fubar/fubar' -ErrorAction Stop } |
            Should -Throw 'failed with HTTP error "Not Found" (404) and PagerDuty error "Not Found" (2100)'
    }
}

Describe 'Invoke-PDRestMethod.when api throws an error and ignoring errors' {
    It 'should write no error' { 
        $Global:Error.Clear()
        { Invoke-PDRestMethod -Session $session -Path 'services/fubar/fubar' -ErrorAction Ignore } | Should -Not -Throw
        $Global:Error | Where-Object { $_ -like 'failed with HTTP error * and PagerDuty error' } | Should -BeNullOrEmpty
    }
}

Describe 'Invoke-PDRestMethod.when using self urls' {
    It 'should return objects' {
        $services = Invoke-PDRestMethod -Session $session -Path 'services'
        $service = $services.services[0]
        {
            $urls = & {
                $service.self
                $service.escalation_policy.self
                $service.integrations | Select-Object -ExpandProperty 'self'
            }
            foreach( $url in $urls )
            {
                Invoke-PDRestMethod -Session $session -Uri $url | Should -Not -BeNullOrEmpty
            }
        } | Should -Not -Throw
    }
}

Describe 'Invoke-PDRestMethod.when user passes string for body' {
    It 'should use that string as the body' {
        $expectedBody = 'my body'
        Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PagerDutyAutomation'
        Invoke-PDRestMethod -Session $session -Path 'some/path' -Body $expectedBody
        Assert-MockCalled -CommandName 'Invoke-RestMethod' `
                          -ModuleName 'PagerDutyAutomation' `
                          -ParameterFilter { 
                              $Body | Should -Be $expectedBody
                              return $true
                          }

    }
}

Describe 'Invoke-PDRestMethod.when user passes object for body' {
    It 'should convert object to JSON body' {
        $bodyObject = [pscustomobject]@{
            'one' = 'my body';
            'tow' = 'three';
        }
        Mock -CommandName 'Invoke-RestMethod' -ModuleName 'PagerDutyAutomation'
        Invoke-PDRestMethod -Session $session -Path 'some/path' -Body $bodyObject
        Assert-MockCalled -CommandName 'Invoke-RestMethod' `
                          -ModuleName 'PagerDutyAutomation' `
                          -ParameterFilter { 
                              $Body | Should -Be ($bodyObject | ConvertTo-Json) 
                              return $true
                          }
    }
}