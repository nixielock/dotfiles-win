# ConvertTo-ParameterSplat
# load the function globally when script is called

function ConvertTo-ParameterSplat {
	[CmdletBinding()]
    [Alias('splat')]
    param (
        # literal string to convert to splatted parameters
        [parameter(Mandatory=$true, Position=0, ValueFromPipeline)]
        [string] $LiteralInvocation
    )

    process {
        ro "|@p|parsing command..."

        $invocationSplit = $LiteralInvocation -split ' -' | Where-Object { $_ -match '\S' }
    
        $invocationCommand = $invocationSplit[0]
        if ($invocationSplit.Count -eq 1) {
            ro "|@e|no parameters to splat!`n"
            return $invocationCommand
        }

        ro "splatting |@b|$invocationCommand... " -n

        $commandParamsName = "$($invocationCommand -replace '-','')Params" -replace '^.', "$($invocationCommand.Substring(0,1).ToLower())"

        $outputLiteral = @"
|@ yellow|`$$commandParamsName|@| = @{
"@
        # end here-string

        $paramList = @()

        foreach ($paramPair in ($invocationSplit[1..($invocationSplit.Length - 1)]).Trim()) {
            $null = $paramPair -match '(?<paramName>\w+)(\s+(?<paramValue>.*))?$'
            $paramName = $matches.paramName
            $paramValue = $matches.paramValue

            if (!$paramValue) {
                $paramValue = '$true'
            } elseif (-not ($paramValue[0] -match "[\$\`"\'\(]")) {
                $paramValue = "`"$paramValue`""
            }

            #$paramValue = $paramValue -replace '"([^"]+)"', '|@b|"|@|$1|@b|"|@|'
            $paramValue = $paramValue -replace '\$\(([^\)]+)\)', '|@ red|$$(|@|$1|@ red|)|@|'
            $paramValue = $paramValue -replace '(\$\w+)', '|@ green|$1|@|'

            $outputLiteral += @"

    |@b|$paramName|@| = $paramValue
"@
            # end here-string
        }

        $outputLiteral += @"

}
|@b|$invocationCommand|@w| @$commandParamsName|@|
"@
    
        ro "|@s|done!"
        ($outputLiteral -replace '\|@[\w\ ]*\|', '') | clip
        ro "splatted command |@p|copied to clipboard!`n"

        $outputLiteral | ro
    }
}
