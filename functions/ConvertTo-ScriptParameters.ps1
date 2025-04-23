# ---- scriptsplat
# parses an RDEX parameter block to return a script invocation

function scriptsplat {
	[CmdletBinding()]
    param (
        # literal string to convert to splatted parameters
        [parameter(Mandatory=$true, Position=0, ValueFromPipeline)]
        [string] $ParameterBlock,

        # path to script
        [parameter(Position=1, ValueFromPipeline)]
        [string] $ScriptPath,

        # use variables named after the parameter as placeholders, as in Rundeck inline scripts
        [alias('nv')]
        [switch] $UseNamedVariables
    )

    # -- INIT
    
    ro "|@p|parsing parameter block..."

    $paramRegex = '(?:\[)(?<pType>[\w\.\[\]]+)(?:\] *\$)(?<pName>\w+)'
    $paramDetails = ($ParameterBlock | select-string $paramRegex -All).matches

    $outputLiteral = @"
|@ yellow|`$scriptParams|@| = @{
"@
    # end here-string

    # -- ADD PARAMS
    
    # iterate over each param to add to splat params
    foreach ($p in $paramDetails) {
        $paramName = $p.groups['pName'].value

        if ($UseNamedVariables) {
            $placeholder = "`$$paramName"
        } else {
            $placeholder = "#$($p.groups["pType"].value)"
        }

        $outputLiteral += @"

    |@b|$paramName|@| = $placeholder
"@
        # end here-string
    }

    # -- FINALISE

    # use placeholder path if not specified
    if ($ScriptPath -match '\S') {
        $pathString = "|@b|`"$ScriptPath`""
    } else {
        $pathString = '"path\to\script.ps1"'
    }

    # add invocation to output literal
    $outputLiteral += @"

}
. $pathString|@w| @scriptParams|@|
"@
    
    # copy invocation to clipboard without ro tags
    ro "|@s|done!"
    ($outputLiteral -replace '\|@[\w\ ]*\|', '') | clip
    ro "splatted invocation |@p|copied to clipboard!`n"

    # display ro-formatted output
    $outputLiteral | ro
}
