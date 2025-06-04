# ConvertTo-ParameterSplat
# load the function globally when script is called

function splat {
	[CmdletBinding()]
    param (
        # literal string to convert to splatted parameters
        [parameter(Position=0, Mandatory, ValueFromPipeline)]
        [string] $LiteralInvocation
    )

    process {
        ro "|@p|parsing command..."

        # -- SETUP

        # split by param names
        $invocationSplit = $LiteralInvocation -split ' -' |?ne
    
        # manage first positional param
        if ($invocationSplit[0] -match '^[a-z\d\-]+ (?<pos>.+)$') {
            $pos = "InputObject $($matches.pos)"

            $newSplit = @($invocationSplit[0] -replace '([^\ ]+) .+$','$1')
            $newSplit += @($pos)
            if ($invocationSplit.Count -gt 1) {
                $newSplit += $invocationSplit[1..($invocationSplit.Count -1)]
            }

            $invocationSplit = $newSplit
        }

        $invocationCommand = $invocationSplit[0]
        
        if ($invocationSplit.Count -eq 1) {
            ro "|@e|no parameters to splat!`n"
            return $invocationCommand
        }

        # set splat variable name
        ro "splatting |@b|$invocationCommand... " -n
        $commandParamsName = "$($invocationCommand -replace '-','')Params"
        $commandParamsName = $commandParamsName -replace '^.', "$($invocationCommand.Substring(0,1).ToLower())"

        # init output literal
        $outputLiteral = @"
|@ yellow|`$$commandParamsName|@| = @{
"@
        # end here-string

        # -- ADD PARAMETERS
        
        # iterate over each parameter pair
        $pairList = ($invocationSplit[1..($invocationSplit.Length - 1)]).Trim()
        foreach ($paramPair in $pairList) {
            # assign match to null to populate $matches for name and value
            $null = $paramPair -match '(?<paramName>\w+)(\s+(?<paramValue>.*))?$'
            $paramName = $matches.paramName
            $paramValue = $matches.paramValue

            # set parameter to true if it has no value
            if (!$paramValue) {
                $paramValue = '$true'

            # add quotes if parameter isn't quoted and isn't a variable, hashtable, etc.
            } elseif (-not ($paramValue[0] -match "[\$\`"\'\(]|@[\{\(]")) {
                $paramValue = "`"$paramValue`""
            }

            # highlight with ro tags
            $paramValue = $paramValue -replace '\$\(([^\)]+)\)', '|@ red|$$(|@|$1|@ red|)|@|'
            $paramValue = $paramValue -replace '(\$\w+)', '|@ green|$1|@|'
            #$paramValue = $paramValue -replace '"([^"]+)"', '|@b|"|@|$1|@b|"|@|'

            # add parameter assignment to output literal
            $outputLiteral += @"

    |@b|$paramName|@| = $paramValue
"@
            # end here-string
        }

        # -- FINALISE
        
        # add invocation to output literal
        $outputLiteral += @"

}
|@b|$invocationCommand|@w| @$commandParamsName|@|
"@
    
        # copy splat to clipboard without ro tags
        ro "|@s|done!"
        ($outputLiteral -replace $pwsh_roFormatTag, '') | clip
        ro "splatted command |@p|copied to clipboard!`n"

        # display splat with ro formatting
        $outputLiteral | ro
    }
}
