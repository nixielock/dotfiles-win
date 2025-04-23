function graph-get {
    [CmdletBinding()]
    param (
        [parameter(Position = 0, Mandatory)]
        [string] $Uri
    )

    try {
        ro "|@ darkgray|invoking request to |@b|/beta/$Uri|@ darkgray|..."
        
        $returnStatus = "n/a"
        $invokeMgGraphRequestParams = @{
            Method = "GET"
            Uri = $Uri
            StatusCodeVariable = 'returnStatus'
            ErrorAction = 'Stop'
        }
        $response = Invoke-MgGraphRequest @invokeMgGraphRequestParams

        ro "|@ darkgray|response for request |@b|$Uri|@darkgray|:"
        wr "return status: " -n
        wr "$returnStatus" -f green
        $response | fl *

    } catch {
        $errorResponse = $_.ErrorDetails -split "`n"
        $errorJson = ($errorResponse[-1] | ConvertFrom-Json -Depth 99).error
        
        wr "exception returned from graph API:" -f red
        wr "----------------------------------" -f red
        $errorResponse[0]
        wr "$($errorResponse[1])" -f red
        $errorResponse[2..($errorResponse.Length - 2)] -replace '^([^:]+): ','|@p|$1: |@|' | ro
        wr "-- response JSON:"
        ro "|@p|code: |@|$($errorJson.code)"
        ro "|@p|message: |@|$($errorJson.message)"
        wr "innerError: " -f cyan
        (($errorJson.innerError |fl | out-string) -split "`n") -replace '^([^:]+): ','  |@p|$1: |@|' |? { $_ -match '\w' } | ro
        wr "----------------------------------" -f red
    }
}
