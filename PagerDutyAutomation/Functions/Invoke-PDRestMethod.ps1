
function Invoke-PDRestMethod
{
    <#
    .SYNOPSIS
    Calls endpoints on the PagerDuty API.

    .DESCRIPTION
    The `Invoke-PDRestMethod` calls an endpoint on the PagerDuty API. Pass the session to use to the `Session` parameter
    (create a session with the `New-PDSession` function). Pass the path to the endpoint to the `Path` parameter. 
    
    If the endpoint returns paged results, `Invoke-PDRestMethod` will return an object for the first page of results.
    The return object will have these properties (see https://developer.pagerduty.com/docs/rest-api-v2/pagination/):
    
    * `limit`, which is the number of objects returned.
    * `offset`, which is the index of the first item in the results across all pages.
    * `more`, which is `$true` if there are more results and `$false` otherwise.
    * `total`, which is `$null` by default. If you want to know the total number of records across all pages, use the 
      `IncludeTotal` parameter, and then this property will be the total number of objects.

    Use the `Offset` parameter to control the start index of the records to return. Use the `Count` parameter to control
    how many records to return in each request.

    If you don't want to paginate, use the `All` parameter to return all records.

    If you want to find a specific item, you can pass a script block expression to the `First` parameter. 
    `Invoke-PDRestMethod` will return the first object that returns `$true` when passed through that filter using 
    `Where-Object`. `Invoke-PDRestMethod` will automatically page through results until it finds an item and stops
    making requests once the object is found.

    If you want to return all items that match an expression, pass the expression as a script block to the `Filter`
    parameter. `Invoke-PDRestMethod` will page through all results and return objects that return `$true` when passed
    to the script block using the `Where-Object` cmdlet.

    If you have the full URL to an item (usually from the `self` property on an object returned by an endpoint), you 
    can pass that to the `Uri` parameter.

    If you're calling an endpoint that receives a JSON body, pass the JSON to the `Body` parameter. You can also pass in
    an object, and `Invoke-PDRestMethod` will convert it to JSON for you (e.g. `$Body | ConvertTo-Json -Depth 50`). Use
    the `Method` parameter to use the correct REST verb.

    .EXAMPLE
    $page = Invoke-PDRestMethod -Session $session -Path 'services'

    Demonstrates how to use `Invoke-PDRestMethod` to get a single page of records.

    .EXAMPLE
    $page2 = Invoke-PDRestMethod -Session $session -Path 'services' -Offset 25

    Demonstrates how to get a different page of results using the `Offset` parameter.

    .EXAMPLE
    $page = Invoke-PDRestMethod -Session $session -Path 'services' -Count 100

    Demonstrates how to increase the number of records returned by each request using the `Count` parameter.

    .EXAMPLE
    $services = Invoke-PDRestMethod -Session $session -Path 'services' -All

    Demonstrates how to use the `All` parameter to skip paging the results and return all objects.

    .EXAMPLE
    $page = Invoke-PDRestMethod -Session $session -path 'services' -IncludeTotal
    
    Demonstrates how to use the `IncludeTotal` parameter to include the total number of results across all pages in the
    return object.

    .EXAMPLE
    Invoke-PDRestMethod -Session $session -Path 'services' -First { $_.name -eq 'My Service' }

    Demonstrates how to use the `First` parameter to return the first item that gets selected by a script block. The 
    script block is passed to `Where-Object` to select the object to return. Once an object is found, no further 
    requests are made to PagerDuty.

    .EXAMPLE
    Invoke-PDRestMethod -Session $session -Path 'services' -Filter { $_.name -like '*filter*' }

    Demonstrates how to use the `Filter` parameter to return all items that are selected by a script block. The script
    block is passed to `Where-Object` to select the objects to return.

    .EXAMPLE
    Invoke-PDRestMethod -Session $session -Uri $item.self

    Demonstrates how to use the full `self` URLs returned on PagerDuty objects to get specific objects.

    .EXAMPLE
    Invoke-PDRestMethod -Session $session -Path 'services' -Body $json -Method Post

    Demonstrates how to create an item by passing the new object's JSON to the `Body` parameter.

    .EXAMPLE
    Invoke-PDRestMethod -Session $session -Path 'services' -Body $newService -Method Post

    Demonstrates how to create an item by passing an object to the `Body` parameter. The `Invoke-PDRestMethod` function
    converts the object to JSON using `ConvertTo-Json`.
    #>
    [CmdletBinding(DefaultParameterSetName='Pagination')]
    param(
        [Parameter(Mandatory)]
        [Object]$Session,

        [Parameter(Mandatory,ParameterSetName='Uri')]
        [Uri]$Uri,

        [Parameter(Mandatory,ParameterSetName='Pagination')]
        [Parameter(Mandatory,ParameterSetName='First')]
        [Parameter(Mandatory,ParameterSetName='Filter')]
        [Parameter(Mandatory,ParameterSetName='All')]
        [String]$Path,

        [Microsoft.PowerShell.Commands.WebRequestMethod]$Method = [Microsoft.PowerShell.Commands.WebRequestMethod]::Get,

        [Object]$Body,

        [Parameter(ParameterSetName='Pagination')]
        [int]$Offset,

        [Parameter(ParameterSetName='Pagination')]
        [int]$Count,

        [Parameter(ParameterSetName='Pagination')]
        [switch]$IncludeTotal,

        [Parameter(ParameterSetName='First')]
        [scriptblock]$First,

        [Parameter(ParameterSetName='Filter')]
        [scriptblock]$Filter,

        [Parameter(ParameterSetName='All')]
        [switch]$All
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    if( $PSCmdlet.ParameterSetName -in @('First', 'Filter', 'All') )
    {
        $parameters = [Collections.Generic.Dictionary[String,Object]]::New($PSBoundParameters)
        [void]$parameters.Remove('First')
        [void]$parameters.Remove('Filter')
        [void]$parameters.Remove('All')

        $resultPropertyName = $null

        $startAt = 0
        do
        {
            $page = Invoke-PDRestMethod @parameters -Offset $startAt -Count 10000
            $startAt += $page.limit

            # The property holding the return objects is different across endpoints.
            if( -not $resultPropertyName )
            {
                $propertyNames = $page | Get-Member -MemberType 'NoteProperty' | Select-Object -ExpandProperty 'Name'
                foreach( $propertyName in $propertyNames )
                {
                    $propertyType = $page.$propertyName.GetType()
                    if( $propertyType.IsArray )
                    {
                        $resultPropertyName = $propertyName
                        break
                    }
                }
            }

            $results =
                $page.$resultPropertyName |
                Where-Object { 
                    if( $First )
                    {
                        $_ | Where-Object $First
                    }

                    if( $Filter )
                    {
                        $_ | Where-Object $Filter
                    }

                    if( $All )
                    {
                        return $true
                    }
                }

            if( $First -and $results )
            {
                return $results | Select-Object -First 1 | Write-Output
            }

            $results | Write-Output
        }
        while( $page.more )

        return
    }

    $headers = @{
        'Authorization' = "Token token=$($Session.Token)";
        'Accept' = 'application/vnd.pagerduty+json;version=2';
    }

    $url = $null
    if( $PSCmdlet.ParameterSetName -eq 'Uri' )
    {
        $url = $Uri.ToString()
    }
    else
    {
        $queryString = & {
            if( $Offset )
            {
                "offset=$($Offset)" | Write-Output
            }

            if( $IncludeTotal )
            {
                "total=true" | Write-Output
            }

            if( $Count )
            {
                "limit=$($Count)" | Write-Output
            }
        }

        if( $queryString )
        {
            $queryString = "?$($queryString -join '&')"
        }
        $url = "$($Session.Url)/$($Path.TrimStart('/'))$($queryString)" 
    }

    $conditionalParams = @{}

    if( $Body )
    {
        if( $Body -is [string] )
        {
            $conditionalParams['Body'] = $Body
        }
        else
        {
            $conditionalParams['Body'] = $Body | ConvertTo-Json -Depth 50
        }
    }

    $result = $null
    try
    {
        $result = Invoke-RestMethod -Uri $url `
                                    -Headers $headers `
                                    -ContentType 'application/json' `
                                    -Method $Method `
                                    @conditionalParams
    }
    catch
    {
        $pderror = $_.ErrorDetails | ConvertFrom-Json
        
        $response = $_.Exception.Response
        $httpStatusDesc = & {
            if( $response | Get-Member -Name 'ReasonPhrase' )
            {
                return $response.ReasonPhrase
            }

            return $response.StatusDescription
        }
        $httpStatusCode = $_.Exception.Response.StatusCode
        $msg = "Request to $($url) failed with HTTP error ""$($httpStatusDesc)"" ($([int]$httpStatusCode)) and " +
               "PagerDuty error ""$($pderror.error.message)"" ($($pderror.error.code))."
        
        if( $pderror.error | Get-Member -Name 'errors' )
        {
            $msg = "$($msg) $($pdError.error.errors -join '. ')."
        }
        Write-Error -Message $msg -ErrorAction $ErrorActionPreference
        return
    }

    if( -not $result )
    {
        return
    }

    if( -not ($result | Get-Member -Name 'offset') )
    {
        $objectPropertyName =
            $result |
            Get-Member -MemberType NoteProperty |
            Select-Object -First 1 |
            Select-Object -ExpandProperty 'Name'
        return $result | Select-Object -ExpandProperty $objectPropertyName
    }

    return $result
}